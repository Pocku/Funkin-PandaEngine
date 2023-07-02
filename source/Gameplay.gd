extends Node2D

onready var ui=$UI;
onready var getReady=$UI/GetReady;
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
var offsyncAllowed=30.0;

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

var bf=null;
var dad=null;
var gf=null;
var stage=null;

var notesQueue=[];
var eventsQueue=[];

func _ready():
	Conductor.connect("beat",self,"onBeat");
	loadSong();
	
	stage=load("res://source/stages/%s.tscn"%[chart.stage]).instance();
	add_child(stage);
	for i in 3:
		var charId=chart[["player1","player2","player3"][i]];
		if charId=="" || not charId in Game.charactersList:
			continue;
		var chara=load("res://source/characters/%s.tscn"%[charId]).instance();
		var data=stage[["bf","dad","gf"][i]];
		stage.add_child(chara);
		chara.position=Vector2(data.x,data.y);
		chara.scale=Vector2.ONE*data.scale;
		chara.scale.x*=-1 if data.flip else 1.0;
		stage.move_child(chara,min(data.depth,stage.get_child_count()));
		set(["bf","dad","gf"][i],chara);
	
	cam.position=Vector2(stage.cam.x,stage.cam.y);
	cam.rotation=deg2rad(stage.cam.rotation);
	cam.baseZoom=stage.cam.zoom;
	
	combo.setBaseScale(0.75);
	move_child(combo,get_child_count());
	
	hpbar.tint_under=Color.red;
	hpbar.tint_progress=Color.lime;
	
	for i in 2:
		var strum=Strums.new();
		strums.add_child(strum);
		strum.position.x=[-500,148][i];
		strum.character=get(["dad","bf"][i]);
		
	strums.get_child(1).isPlayer=true;	
	strums.position.y=[-264,270][int(Settings.downScroll)];
	
	hpbar.rect_position.y=[298,-298][int(Settings.downScroll)];
	scoreLabel.rect_position.y=hpbar.rect_position.y+32;
	updateScoreLabel();
	
	Conductor.setBpm(chart.bpm);
	Conductor.waitTime=Conductor.crochet*5;
	startCountdown();
	

func _process(dt):
	Conductor.waitTime=max(Conductor.waitTime-dt,0.0);
	if songStarted:
		Conductor.time=min(Conductor.time+dt,inst.stream.get_length());
		if Conductor.time+0.1>inst.stream.get_length(): Conductor.time=0.0;
		var time=(inst.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		if abs(time-Conductor.time)>(offsyncAllowed/1000.0):
			for i in [inst,voices]: i.seek(Conductor.time);
	
	if !notesQueue.empty():
		var dist=((notesQueue[0].time+Conductor.waitTime)-Conductor.time)*Game.scrollScale;
		if dist<960:
			createNote(notesQueue[0]);
			notesQueue.remove(0);
	
func _physics_process(dt):
	hpbar.value=lerp(hpbar.value,health,0.2);
	playerIcons.position.x=601-float(hpbar.value/100.0)*601;
	sicksLabel.bbcode_text="SICKS: %s \nGOODS: %s \nBADS:  %s \nSHITS: %s"%[sicks,goods,bads,shits];

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
	
func onBeat(beat):
	cam.bumpScale=-0.02;
	tw.interpolate_property(playerIcons,"scale",Vector2.ONE*1.08,Vector2.ONE,Conductor.crochet/4.0);
	tw.start();

func startCountdown():
	var countdownScale=1.0;
	match Game.uiSkin:
		"pixel": countdownScale=6.0;
	
	for i in 5:
		yield(get_tree().create_timer(Conductor.crochet),"timeout");
		if i>3: continue;
		Conductor.addBeat();
		Sfx.play("intro%s-%s"%[["3","2","1","Go"][i],Game.uiSkin]);
		getReady.texture=load("res://assets/images/ui-skin/%s/%s.png"%[Game.uiSkin,["","ready","set","go"][i]]) if i>0 else null;
		tw.interpolate_property(getReady,"scale",Vector2.ONE*countdownScale*0.8,Vector2.ONE*countdownScale*0.6,Conductor.crochet,Tween.TRANS_CIRC,Tween.EASE_OUT);
		tw.interpolate_property(getReady,"modulate:a",4.0,0.0,Conductor.crochet,Tween.TRANS_CIRC,Tween.EASE_OUT);
		tw.start();
		
	for i in [inst,voices]: i.play(0.0);
	Conductor.beatTime=0.0;
	Conductor.beatCount=0;
	Conductor.addBeat();
	songStarted=true;
	
	
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
			
	var note=load("res://source/notes/%s.tscn"%[path]).instance();
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
	f.open("res://assets/data/%s/%s.json"%[Game.song,Game.mode],File.READ);
	chart=parse_json(f.get_as_text()).song;
	f.close();
	
	if !chart.has("player3"): chart["player3"]="gf";
	if !chart.has("cutscene"): chart["cutscene"]="";
	if !chart.has("stage"): chart["stage"]="stage";
	if !chart.has("events"): chart["events"]=[];
	if !chart.stage in Game.stagesList: chart.stage="stage";
	
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
					"time":rawData[0]/1000.0,
					"column":rawData[1],
					"length":rawData[2]/1000.0,
					"type":rawData[3],
					"mustHit":chart.notes[i].mustHitSection
				}
				notesQueue.append(nData);
	
	inst.stream=load("res://assets/songs/%s/Inst.ogg"%[Game.song]);
	voices.stream=load("res://assets/songs/%s/Voices.ogg"%[Game.song]);
	notesQueue.sort_custom(self,"sortNotes");

func muffleSong():
	tw.interpolate_property(inst,"volume_db",-40.0,0.0,0.5);
	tw.interpolate_property(voices,"volume_db",-40.0,0.0,0.5);
	tw.start();

func unMuffleSong():
	inst.volume_db=0.0;
	voices.volume_db=0.0;

func updateScoreLabel():
	scoreLabel.bbcode_text="[center]Score:%s    Accuracy: %s    Misses: %s"%[score,str(str(stepify(float((notesHit/notesTotal)*100.0 if notesTotal>0 else 0),0.01)).pad_decimals(2),"%"),misses];
	
func sortNotes(a,b):
	return a.time<b.time;

func sortEvents(a,b):
	return a[0]<b[0];
