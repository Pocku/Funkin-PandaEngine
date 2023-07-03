extends Node

signal noteHit(data);
signal noteHeld(data);
signal noteMiss(data);
signal noteHeldMiss(data);
signal playerDied;

var noteTypes=[
	"","Hurt","Alt"
]
var eventType=[
	"","camZoom","camMove","addBeatZoom"
]

var song="black-sun";
var mode="hard";
var uiSkin="default";
var scrollScale=1400.0;
var botMode=false;

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_F4,KEY_F11] && !ev.echo && ev.pressed:
			OS.window_fullscreen=!OS.window_fullscreen;

func getCharacterList():
	var rawList=getFilesInFolder("source/characters/");
	var list=[];
	for i in len(rawList): 
		if !str(rawList[i]).ends_with(".gd"):
			list.append(str(rawList[i]).replace(".tscn",""));
	list.push_front("");
	return list;

func getSongList():
	return getFilesInFolder("assets/songs/");

func getStageList():
	var list=getFilesInFolder("source/stages/");
	for i in len(list): list[i]=str(list[i]).replace(".tscn","");
	return list;

func getFilesInFolder(path):
	var files=[];
	var dir=Directory.new();
	dir.open("res://"+path);
	dir.list_dir_begin(true);
	var file = dir.get_next();
	while file!='':
		files+=[file];
		file=dir.get_next();
	return files;
