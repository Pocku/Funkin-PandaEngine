extends Node

signal bpmChanged;

var bpm=100;
var crochet=60.0/bpm;
var stepCrochet=crochet/4.0;
var time=0.0;
var waitTime=0.0;
var beatCount=0;

func reset():
	bpm=100;
	crochet=60.0/bpm;
	stepCrochet=crochet/4.0;
	beatCount=0.0;
	time=0.0;

func setBpm(b):
	bpm=b;
	crochet=float(60.0/bpm);
	stepCrochet=float(crochet/4.0);
	printt("BPM CHANGED TO",bpm);
	emit_signal("bpmChanged");
