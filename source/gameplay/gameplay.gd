extends Node2D

onready var ui=$UI;
onready var uiCanvasMod=$UI/CanvasMod;
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
var countdownStarted=false;
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
var dead=false;

var bf=null;
var dad=null;
var gf=null;

var stage=null;
var events=null;
var songScript=null;
var sectionTarget=null;
var camMoveWithSection=true;
var isGfSection=false;

var notesQueue=[];
var eventsQueue=[];

var camSingOffset=Vector2.ZERO;
var camSingLen=8.0;

func _ready():
	Game.connect("cutsceneFinished",self,"startCountdown");
	Conductor.connect("beat",self,"onBeat");
	Conductor.reset();
	
	inst.connect("finished",self,"onSongFinished");
	loadSong();
	
	Game.scrollScale=1000.0*chart.speed;
	uiCanvasMod.color.a=1.0;
	
	if false:
		Conductor.time=inst.stream.get_length()-6.0;
		while notesQueue[0].time<=Conductor.time:
			notesQueue.remove(0);
	
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
		stage.move_child(chara,min(data.depth,stage.get_child_count()));
		set(["bf","dad","gf"][i],chara);
	
	cam.position=Vector2(stage.cam.x,stage.cam.y);
	cam.rotation=deg2rad(stage.cam.rotation);
	tw.interpolate_property(cam,"baseZoom",stage.cam.zoom*0.25,stage.cam.zoom,1.0,Tween.TRANS_QUART,Tween.EASE_OUT);
	tw.start();
	
	combo.scale*=0.64;
	move_child(combo,get_child_count());
	
	hpbar.tint_under=Color.red if Settings.classicHud else dad.healthColor;
	hpbar.tint_progress=Color.lime if Settings.classicHud else bf.healthColor;
	playerIcons.get_child(0).texture=dad.icon;
	playerIcons.get_child(1).texture=bf.icon;
	
	for i in 2:
		var strum=StrumLine.new();
		strum.isPlayer=[false,true][i];
		strums.add_child(strum);
		strum.position.x=[-500,148][i];
		strum.character=["dad","bf"][i];
	strums.position.y=[-264,270][int(Settings.downScroll)];
	strums.get_child(0).visible=Settings.enemyNotes;
	
	if Settings.midScroll:
		strums.get_child(1).position.x=-strums.get_child(1).getWidth()/2.0;
		strums.get_child(0).position.x=-(strums.get_child(0).getWidth()+161/2);
		strums.get_child(0).modulate.a=0.2;
	
	hpbar.visible=!Settings.hideHud;
	scoreLabel.visible=!Settings.hideHud;
	sicksLabel.visible=!Settings.hideHud;
	
	hpbar.rect_position.y=[298,-298][int(Settings.downScroll)];
	scoreLabel.rect_position.y=hpbar.rect_position.y+32;
	updateScoreLabel();
	
	Conductor.setBpm(chart.bpm);
	Conductor.waitTime=Conductor.crochet*5;
	
	var songScriptPath="res://source/gameplay/songs/%s.gd"%[Game.song];
	songScript=preload("res://source/gameplay/song-script.gd").new() if !ResourceLoader.exists(songScriptPath) else load(songScriptPath).new();
	add_child(songScript);
	
	events=preload("res://source/gameplay/events.gd").new();
	add_child(events);
	
	if Game.storyMode:
		var cutscenePath="dialogue";
		match Game.cutscene:
			"zap":
				cutscenePath="video";
		var cutscene=load("res://source/cutscenes/%s.tscn"%[cutscenePath]).instance();
		add_child(cutscene);
	else:
		Game.emit_signal("cutsceneFinished");
	
	
func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_7] && songStarted:
				Game.changeScene("charter/charter");
			
			if ev.scancode in [KEY_R] && songStarted && !songFinished && !dead:
				onPlayerDeath();
		
func _process(dt):
	if countdownStarted: Conductor.waitTime=max(Conductor.waitTime-dt,0.0);
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
		if dist<930:
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
		onSectionChanged();
		songScript.call("onSectionChanged",curSection,chart.notes[int(curSection)]);
		printt("SECTION CHANGED:",curSection);
	
	songScript.call("onUpdatePost",dt);
	
func _physics_process(dt):
	hpbar.value=lerp(hpbar.value,health,0.32);
	playerIcons.position.x=601-float(hpbar.value/100.0)*601;
	sicksLabel.bbcode_text="SICKS: %s \nGOODS: %s \nBADS:  %s \nSHITS: %s"%[sicks,goods,bads,shits];
	
	if health<=0.0 && !dead:
		Game.emit_signal("playerDied");
		onPlayerDeath();
		dead=true;
	
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
		if data[4] && !Game.uiSkin in ["pixel"]: #Check if it's a player note:
			strums.get_child(1).get_child(data[1]).createSplash();
	
	combo.pop(rating);
	score+=points;
	notesHit+=acc;
	set(str(rating,"s"),get(str(rating,"s"))+1);
	updateScoreLabel();

func startCountdown():
	var countdownScale=1.0;
	countdownStarted=true;
	songScript.call("onCountdownStarted");
	
	for i in strums.get_child_count():
		var strumline=strums.get_child(i);
		strumline.revealArrows();
		
	#tw.interpolate_property(uiCanvasMod,"color:a",0.0,1.0,0.4,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	#tw.start();
	
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
	onSectionChanged()
	
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
			get_tree().paused=false;
		else:
			Game.song=Game.songsQueue[0];
			Game.reloadScene();
	else:
		Game.changeScene("menus/freeplay/freeplay");
		Music.play("freaky");
		get_tree().paused=false;
	Game.saveGame();
	
func onSectionChanged():
	var sectData=chart.notes[curSection];
	var mustHit=sectData.mustHitSection;
	var gfSection=sectData.gfSection;
	var camTarget=Vector2();
	var camMoveDur=0.8;
	
	sectionTarget=bf if mustHit else dad;
	sectionTarget=gf if gfSection else sectionTarget;
	
	playerIcons.get_child(0).texture=dad.icon;
	playerIcons.get_child(1).texture=bf.icon;
	if !Settings.classicHud: 
		hpbar.tint_under=dad.healthColor;
		hpbar.tint_progress=bf.healthColor;
	
	if gfSection:
		if !mustHit:
			playerIcons.get_child(0).texture=gf.icon;
			if !Settings.classicHud: hpbar.tint_under=gf.healthColor;
		else:
			playerIcons.get_child(1).texture=gf.icon;
			if !Settings.classicHud: hpbar.tint_progress=gf.healthColor;
		
	Conductor.setBpm(getLastBpm(curSection));
	if camMoveWithSection:
		camTarget=sectionTarget.global_position+sectionTarget.camOffset*sectionTarget.scale;
		tw.interpolate_property(cam,"global_position",cam.global_position,camTarget,camMoveDur,Tween.TRANS_QUART,Tween.EASE_OUT);
		tw.start();

func onPlayerDeath():
	Game.tempData={
		"player":[chart.player1,bf.global_position,bf.scale,bf.rotation],
		"cam":[cam.global_position,cam.zoom,cam.rotation]
	}
	Game.songsData[Game.song][3]+=1;
	Game.changeScene("gameover/gameover",false);
	Game.saveGame();
	print("PLAYER DIED!");

func createNote(nData):
	var tStrum=null;
	var isPlayer=false;
	if nData.mustHit && nData.column>-1 && nData.column<4 || !nData.mustHit && nData.column>3 && nData.column<8:
		tStrum=strums.get_child(1);
		isPlayer=true;
	if !nData.mustHit && nData.column>-1 && nData.column<4 || nData.mustHit && nData.column>3 && nData.column<8:
		tStrum=strums.get_child(0);
	
	var path="note";
	var altAnimPath="";
	
	if nData.altAnim: # Default alt animation by the section
		altAnimPath="-alt";
	
	match nData.type:
		"hurt": path="hurt";
		"alt": altAnimPath="-alt";
		_: path="note";
	
	var note=load("res://source/gameplay/notes/%s.tscn"%[path]).instance();
	var fColumn=int(nData.column)%4;
	note.type=nData.type;
	note.time=nData.time;
	note.column=fColumn;
	note.length=nData.length;
	note.duration=nData.length;
	note.position.y=1600;
	note.isPlayer=isPlayer;
	note.gfNote=nData.gfNote;
	note.strumline=tStrum;
	note.character=["dad","bf"][int(isPlayer)] if !nData.gfNote else "gf";
	note.altAnim=altAnimPath;
	
	var arrow=tStrum.get_child(fColumn);
	arrow.path.add_child(note);
	
	match nData.type:
		"hurt": arrow.ghostNotes.append(note);
		_: arrow.notes.append(note);
	
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
	if !chart.has("uiSkin"): chart["uiSkin"]="default";
	if !chart.has("cutscene"): chart["cutscene"]="";
	if !chart.has("events"): chart["events"]=[];
	if !chart.stage in Game.getStageList(): chart.stage="stage";
	
	Game.cutscene=chart.cutscene;
	Game.uiSkin=chart.uiSkin;
	
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
				var mustHit=chart.notes[i].mustHitSection;
				var altAnim=chart.notes[i].altAnim;
				var isGfNote=false;
				
				if mustHit && rawData[1]<4 && chart.notes[i].gfSection || !mustHit && rawData[1]<4 && chart.notes[i].gfSection:
					isGfNote=true; 
				
				var nData={
					"time":(float(rawData[0])/1000.0)+(Settings.notesOffset/1000.0),
					"column":rawData[1],
					"length":float(rawData[2])/1000.0,
					"type":rawData[3],
					"mustHit":mustHit,
					"altAnim":altAnim,
					"gfNote":isGfNote
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
