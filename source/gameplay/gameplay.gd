extends Node2D

onready var ui=$UI;
onready var pause=$Pause;
onready var countdown=$UI/Countdown;
onready var hpbar=$UI/HpBar;
onready var scoreLabel=$UI/ScoreLabel;
onready var sicksLabel=$UI/SicksLabel;
onready var playerIcons=$UI/HpBar/Icons;
onready var combo=$Combo;
onready var strums=$UI/Strums;
onready var inst=$Inst;
onready var voices=$Voices;
onready var cam=$Cam;
onready var tw=$Tween;

var chart={};
var songStarted=false;
var songFinished=false;
var curSection=0;

var score=0;
var comboTotal=0;
var health=50;
var notesHit=0;
var notesTotal=0;
var goods=0;
var bads=0;
var shits=0;
var sicks=0;
var misses=0;
var fc="?";

var bf=null;
var dad=null;
var gf=null;
var stage=null;
var events=null;
var songScript=null;
var sectionTarget=null;
var camMoveWithSection=true;

var notesQueue=[];
var eventsQueue=[];

var camSingOffset=Vector2.ZERO;
var camSingLen=8.0;

func _ready():
	Conductor.connect("beat",self,"onBeat");
	Conductor.reset();
	
	inst.connect("finished",self,"onSongFinished");
	loadSong();
	
	if true:
		Conductor.time=inst.stream.get_length()-6.0;
		while notesQueue[0].time<=Conductor.time:
			notesQueue.remove(0);
	
	songScript=preload("res://source/gameplay/song-script.gd").new();
	add_child(songScript);
	
	stage=load("res://source/gameplay/stages/%s.tscn"%[chart.stage]).instance();
	add_child(stage);
	
	for i in 3:
		var charId=chart[["player1","player2","player3"][i]];
		if charId=="" || not charId in Game.getCharacterList():
			continue;
		var chara=load("res://source/gameplay/characters/%s.tscn"%[charId]).instance();
		var data=stage[["bf","dad","gf"][i]];
		stage.add_child(chara);
		chara.position=Vector2(data.x,data.y);
		chara.scale=Vector2.ONE*data.scale;
		chara.scale.x*=-1 if chara.flipped else 1.0;
		chara.scale.x*=-1 if data.flip else 1.0;
		stage.move_child(chara,min(data.depth,stage.get_child_count()));
		set(["bf","dad","gf"][i],chara);
	
	cam.position=Vector2(stage.cam.x,stage.cam.y);
	cam.rotation=deg2rad(stage.cam.rotation);
	cam.baseZoom=stage.cam.zoom;
	
	combo.setBaseScale(0.67);
	move_child(combo,get_child_count());
	
	hpbar.tint_under=Color.red;
	hpbar.tint_progress=Color.lime;
	
	for i in 2:
		var strum=Strums.new();
		strum.isPlayer=[false,true][i];
		strums.add_child(strum);
		strum.position.x=[-500,148][i];
		strum.character=get(["dad","bf"][i]);
	strums.position.y=[-264,270][int(Settings.downScroll)];
	strums.get_child(0).visible=Settings.enemyNotes;
	
	if Settings.midScroll:
		strums.get_child(1).position.x=-strums.get_child(1).getWidth()/2.0;
		strums.get_child(0).position.x=-(strums.get_child(0).getWidth()+161/2);
		strums.get_child(0).modulate.a=0.2;
	
	hpbar.visible=!Settings.hideHud;
	scoreLabel.visible=!Settings.hideHud;
	
	hpbar.rect_position.y=[298,-298][int(Settings.downScroll)];
	scoreLabel.rect_position.y=hpbar.rect_position.y+32;
	updateScoreLabel();
	
	Conductor.setBpm(chart.bpm);
	Conductor.waitTime=Conductor.crochet*5;
	
	events=preload("res://source/gameplay/events.gd").new();
	add_child(events);
	
	songScript.call("onCountdownStarted");
	startCountdown();
	
	
func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_7] && songStarted && !ev.echo && ev.pressed:
			Game.changeScene("charter/charter")
	
	
func _process(dt):
	Conductor.waitTime=max(Conductor.waitTime-dt,0.0);
	if songStarted && !songFinished:
		Conductor.time=min(Conductor.time+dt,inst.stream.get_length());
		if Conductor.time>=inst.stream.get_length():
			songFinished=true;
			onSongFinished();
		var time=(inst.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		if abs(time-Conductor.time)>(Game.offsyncAllowed/1000.0):
			for i in [inst,voices]: i.seek(Conductor.time);
		if voices.stream && inst.get_playback_position()>voices.stream.get_length():
			voices.volume_db=-80;
		
	if !notesQueue.empty():
		var dist=((notesQueue[0].time+Conductor.waitTime)-Conductor.time)*Game.scrollScale;
		if dist<960:
			createNote(notesQueue[0]);
			notesQueue.remove(0);
	
	if !eventsQueue.empty():
		var evTime=eventsQueue[0].time;
		var subEvents=eventsQueue[0].events;
		if (evTime-Conductor.time)<=0.0:
			for i in subEvents:
				events.onEvent(i[0],i[1],i[2]);
				songScript.onEvent(i[0],i[1],i[2]);
				printt("EVENT TRIGGERED:",i[0],i[1],i[2]);
			eventsQueue.remove(0);
	
	var nextSect=getSection(Conductor.time);
	if nextSect!=curSection:
		curSection=nextSect;
		onSectionChanged(chart.notes[curSection]);
		songScript.call("onSectionChanged",curSection,chart.notes[int(curSection)]);
		printt("SECTION CHANGED:",curSection);
	
	songScript.call("onUpdatePost",dt);
	
func _physics_process(dt):
	hpbar.value=lerp(hpbar.value,health,0.2);
	playerIcons.position.x=601-float(hpbar.value/100.0)*601;
	sicksLabel.bbcode_text="SICKS: %s \nGOODS: %s \nBADS:  %s \nSHITS: %s"%[sicks,goods,bads,shits];
	
	if is_instance_valid(sectionTarget):
		match sectionTarget.getCurAnim():
			"singLeft":
				camSingOffset=Vector2.LEFT*camSingLen;
			"singDown":
				camSingOffset=Vector2.DOWN*camSingLen;
			"singUp":
				camSingOffset=Vector2.UP*camSingLen;
			"singRight":
				camSingOffset=Vector2.RIGHT*camSingLen;
			"": pass;
			_:
				camSingOffset=Vector2.ZERO;
	cam.offset=lerp(cam.offset,camSingOffset,0.08);
	updateFC();
	
func popUpScore(data):
	var ms=abs(data[0]-Conductor.time);
	var rating="shit";
	var points=0;
	var acc=0.0;
	
	if ms<0.17:
		rating="shit";
		points=25;
		acc=0.1;
	if ms<0.12:
		rating="bad";
		points=100;
		acc=0.3;
	if ms<0.08:
		rating="good";
		points=500;
		acc=0.8;
	if ms<0.04:
		rating="sick";
		points=1000;
		acc=1.0;
	
	combo.pop(rating);
	score+=points;
	notesHit+=acc;
	set(str(rating,"s"),get(str(rating,"s"))+1);
	updateScoreLabel();

func startCountdown():
	var countdownScale=1.0;
	match Game.uiSkin:
		"pixel": countdownScale=8.0;
	
	for i in 5:
		yield(get_tree().create_timer(Conductor.crochet),"timeout");
		if i>3: continue;
		Conductor.addBeat();
		Sfx.play("intro%s-%s"%[["3","2","1","Go"][i],Game.uiSkin]);
		countdown.texture=load("res://assets/images/ui-skin/%s/%s.png"%[Game.uiSkin,["","ready","set","go"][i]]) if i>0 else null;
		tw.interpolate_property(countdown,"scale",Vector2.ONE*countdownScale*0.8,Vector2.ONE*countdownScale*0.6,Conductor.crochet,Tween.TRANS_CIRC,Tween.EASE_OUT);
		tw.interpolate_property(countdown,"modulate:a",4.0,0.0,Conductor.crochet,Tween.TRANS_CIRC,Tween.EASE_OUT);
		tw.start();
		songScript.call("onCountdownBeat",i);
		
	for i in [inst,voices]: i.play(0.0);
	Conductor.beatTime=0.0;
	Conductor.beatCount=0;
	Conductor.addBeat();
	songStarted=true;
	songScript.call("onSongStarted");
	pause.canPause=true;

func onBeat(beat):
	tw.interpolate_property(playerIcons,"scale",Vector2.ONE*1.08,Vector2.ONE,Conductor.crochet/4.0);
	tw.start();

func onSongFinished():
	inst.volume_db=-80.0;
	voices.volume_db=-80.0;
	
	# Replace new score and accuracy
	var newAcc=float(notesHit)/float(notesTotal);
	if Game.songsData[Game.song][1]<newAcc: Game.songsData[Game.song][1]=newAcc;
	if Game.songsData[Game.song][0]<score: Game.songsData[Game.song][0]=score;

	if compareFC(fc,Game.songsData[Game.song][2]):
		Game.songsData[Game.song][2]=fc;
	
	if Game.storyMode:
		if len(Game.songsQueue)>0:
			Game.songsQueue.remove(0);
		if len(Game.songsQueue)==0:
			Game.weeksData[Game.week][0]=true; # Setting week finished to true
			Game.changeScene("menus/storymode/storymode");
			Music.play("freaky");
		else:
			Game.song=Game.songsQueue[0];
			Game.reloadScene();
	else:
		Game.changeScene("menus/freeplay/freeplay");
		Music.play("freaky");
	Game.saveGame();
	
func onSectionChanged(sectData):
	var mustHit=sectData.mustHitSection;
	var camTarget=Vector2();
	var camMoveDur=0.8;
	sectionTarget=bf if mustHit else dad;
	
	Conductor.setBpm(getLastBpm(curSection));
	if camMoveWithSection:
		camTarget=sectionTarget.global_position+sectionTarget.camOffset*sectionTarget.scale;
		tw.interpolate_property(cam,"global_position",cam.global_position,camTarget,camMoveDur,Tween.TRANS_QUART,Tween.EASE_OUT);
		tw.start();

func createNote(nData):
	var tStrum=null;
	var isPlayer=false;
	if nData.mustHit && nData.column>-1 && nData.column<4 || !nData.mustHit && nData.column>3 && nData.column<8:
		tStrum=strums.get_child(1);
		isPlayer=true;
	if !nData.mustHit && nData.column>-1 && nData.column<4 || nData.mustHit && nData.column>3 && nData.column<8:
		tStrum=strums.get_child(0);
	
	var path="note";
	match nData.type:
		_: pass;
			
	var note=load("res://source/gameplay/notes/%s.tscn"%[path]).instance();
	var fColumn=int(nData.column)%4;
	note.type=nData.type;
	note.time=nData.time;
	note.column=fColumn;
	note.length=nData.length;
	note.duration=nData.length;
	note.position.y=1600;
	note.isPlayer=isPlayer;
	
	var arrow=tStrum.get_child(fColumn);
	arrow.path.add_child(note);
	arrow.notes.append(note);
	
	if isPlayer && nData.type=="":
		notesTotal+=1;
			
func loadSong():
	var f=File.new();
	f.open("res://assets/data/songs/%s/%s.json"%[Game.song,Game.mode],File.READ);
	chart=parse_json(f.get_as_text()).song;
	f.close();
	
	if !chart.has("player3"): chart["player3"]="gf";
	if !chart.has("cutscene"): chart["cutscene"]="";
	if !chart.has("stage"): chart["stage"]="stage";
	if !chart.has("events"): chart["events"]=[];
	if !chart.stage in Game.getStageList(): chart.stage="stage";
	
	for i in len(chart.notes):
		if !chart.notes[i].has("gfSection"): chart.notes[i]["gfSection"]=false;
		if !chart.notes[i].has("sectionBeats"): chart.notes[i]["sectionBeats"]=4;
		if !chart.notes[i].has("altAnim"): chart.notes[i]["altAnim"]=false;
		if !chart.notes[i].has("changeBPM"): chart.notes[i]["changeBPM"]=false;
		if !chart.notes[i].has("bpm"): chart.notes[i]["bpm"]=100;
		for n in len(chart.notes[i].sectionNotes):
			if len(chart.notes[i].sectionNotes[n])<4:
				chart.notes[i].sectionNotes[n].append("");
			else:
				if typeof(chart.notes[i].sectionNotes[n][3])!=TYPE_STRING:
					chart.notes[i].sectionNotes[n][3]="";
			
			var rawData=chart.notes[i].sectionNotes[n];
			if rawData[1]>-1:
				var nData={
					"time":(float(rawData[0])/1000.0)+(Settings.notesOffset/1000.0),
					"column":rawData[1],
					"length":float(rawData[2])/1000.0,
					"type":rawData[3],
					"mustHit":chart.notes[i].mustHitSection
				}
				notesQueue.append(nData);
	
	for i in chart.events:
		var data={
			"time":(float(i[0])/1000.0)+(Settings.notesOffset/1000.0),
			"events":i[1]
		}
		eventsQueue.append(data);
	
	var instPath="res://assets/songs/%s/Inst.ogg"%[Game.song];
	var voicesPath="res://assets/songs/%s/Voices.ogg"%[Game.song];
	inst.stream=load(instPath) if ResourceLoader.exists(instPath) else null;
	voices.stream=load(voicesPath) if ResourceLoader.exists(voicesPath) else null;
	notesQueue.sort_custom(self,"sortNotes");
	eventsQueue.sort_custom(self,"sortNotes");

func getSectionStart(index):
	var bpm=chart.bpm;
	var time=0.0;
	for i in range(0,index):
		if (chart.notes[i].changeBPM if chart.notes[i].has("changeBPM") else false):
			bpm=chart.notes[i].bpm
		var sectLen=chart.notes[i].sectionBeats*(60.0/bpm);
		time+=sectLen;
	return time;

func getSection(time):
	var bpm=chart.bpm
	var totalTime=0.0;
	for i in range(0,chart.notes.size()):
		if (chart.notes[i].changeBPM if chart.notes[i].has("changeBPM") else false):
			bpm=chart.notes[i].bpm;
		var sectLen=0.0;
		if chart.notes[i].has("sectionBeats"):
			sectLen=chart.notes[i].sectionBeats*(60.0/bpm);
		if totalTime+sectLen>time:
			return i;
		totalTime+=sectLen;
	return 0;

func getLastBpm(idx):
	var bpm=chart.bpm;
	var time=0.0;
	for i in range(0,idx+1):
		if chart.notes[i].changeBPM: 
			bpm=chart.notes[i].bpm
	return bpm;

func muffleSong():
	tw.interpolate_property(inst,"volume_db",-40.0,0.0,0.5);
	tw.interpolate_property(voices,"volume_db",-40.0,0.0,0.5);
	tw.start();

func unMuffleSong():
	inst.volume_db=0.0;
	voices.volume_db=0.0;

func updateFC():
	var newFc="?";
	if sicks>0: 
		newFc="SFC";
	if goods>0:
		newFc="GFC";
	if bads>0 || shits>0:
		newFc="FC";
	if misses>0 && misses<10:
		newFc="SDCB";
	if misses >= 10:
		newFc="Clear";
	fc=newFc;

func compareFC(newFC,oldFC):
	var newFc="?"
	var FCVals=[0,0];
	
	for i in 2:
		var tFC=[newFC,oldFC][i];
		if tFC=="SFC": FCVals[i]=4;
		if tFC=="GFC": FCVals[i]=3;
		if tFC=="FC": FCVals[i]=2;
		if tFC=="SDCB": FCVals[i]=1;
		if tFC=="Clear" || tFC=="?": FCVals[i]=0;
	
	print(FCVals);
	return FCVals[0]>FCVals[1];

func updateScoreLabel():
	scoreLabel.bbcode_text="[center]Score:%s    Accuracy: %s (%s)    Misses: %s    %s"%[
		score,
		str(str(stepify(float((notesHit/notesTotal)*100.0 if notesTotal>0 else 0),0.01)).pad_decimals(2),"%"),
		fc,
		misses,
		"[color=red](BOTPLAY)" if Game.botMode else ""
	];

func sortNotes(a,b):
	return a.time<b.time;

