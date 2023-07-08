extends Node

signal bpmChanged;
signal beat;

var bpm=100;
var crochet=60.0/bpm;
var stepCrochet=crochet/4.0;
var time=0.0;
var beatTime=0.0;
var waitTime=0.0;
var beatCount=0;

func _process(dt):
	if time>beatTime+crochet:
		beatTime=time;
		addBeat();

func reset():
	bpm=100;
	crochet=60.0/bpm;
	stepCrochet=crochet/4.0;
	beatTime=0.0;
	beatCount=0.0;
	waitTime=0.0;
	time=0.0;

func addBeat():
	beatCount+=1;
	emit_signal("beat",int(beatCount));

func setBpm(b):
	bpm=b;
	crochet=float(60.0/bpm);
	stepCrochet=float(crochet/4.0);
	printt("BPM CHANGED TO",bpm);
	emit_signal("bpmChanged");
