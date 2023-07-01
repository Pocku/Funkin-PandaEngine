extends Node2D

onready var ui=$UI;
onready var getReady=$UI/GetReady;
onready var inst=$Inst;
onready var strums=$UI/Strums;
onready var voices=$Voices;
onready var tw=$Tween;

var chart={};
var songStarted=false;
var offsyncAllowed=30.0;

var score=0;
var combo=0;
var health=0.5;
var notesHit=0;
var notesTotal=0;
var goods=0;
var bads=0;
var shits=0;
var sicks=0;
var misses=0;


func _ready():
	loadSong();
	
	for i in 2:
		var strum=Strums.new();
		strum.position.x=[-500,148][i];
		strums.add_child(strum);
	strums.get_child(0).isPlayer=true;	
	strums.position.y=[-238,230][0];
	
	startCountdown();
	

func _process(dt):
	if songStarted:
		Conductor.time=min(Conductor.time+dt,inst.stream.get_length());
		if Conductor.time+0.1>inst.stream.get_length(): Conductor.time=0.0;
		var time=(inst.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		if abs(time-Conductor.time)>(offsyncAllowed/1000.0):
			for i in [inst,voices]: i.seek(Conductor.time);


func startCountdown():
	for i in 4:
		yield(get_tree().create_timer(Conductor.crochet),"timeout");
		Sfx.play("intro%s-%s"%[["3","2","1","Go"][i],Game.uiSkin]);
		getReady.texture=load("res://assets/images/ui-skin/%s/%s.png"%[Game.uiSkin,["","ready","set","go"][i]]) if i>0 else null;
		tw.interpolate_property(getReady,"scale",Vector2.ONE*0.8,Vector2.ONE*0.6,Conductor.crochet);
		tw.interpolate_property(getReady,"modulate:a",3.0,0.0,Conductor.crochet);
		tw.start();
	for i in [inst,voices]: i.play(0.0);


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
	inst.stream=load("res://assets/songs/%s/Inst.ogg"%[Game.song]);
	voices.stream=load("res://assets/songs/%s/Voices.ogg"%[Game.song]);
