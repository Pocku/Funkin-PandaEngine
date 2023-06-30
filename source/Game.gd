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
	"","Hurt"
]
var eventType=[
	"camZoom","camMove"
]

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
