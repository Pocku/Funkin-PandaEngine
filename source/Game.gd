extends Node

var charactersList=[
	"",
	"bf",
	"dad",
	"gf"
]
var stagesList=[
	"stage"
]
var noteTypes=[
	"","Hurt","Alt"
]
var eventType=[
	"","camZoom","camMove"
]

var song="black-sun";
var mode="hard";
var uiSkin="pixel";
var scrollScale=1400.0;

func getCharacterList():
	var list=getFilesInFolder("source/characters/");
	list.push_front("");
	return list;

func getSongList():
	return getFilesInFolder("assets/songs/");

func getStageList():
	return getFilesInFolder("source/stages/");

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
