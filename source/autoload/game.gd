extends Node

signal cutsceneFinished;
signal noteHit(data);
signal noteHeld(data);
signal noteMiss(data);
signal noteHeldMiss(data);
signal playerDied;


var SCENES = {
	"Boot": "boot",
	"Gameplay": "gameplay/gameplay",
	"Gameover": "gameover/gameover",
	"Charter": "charter/charter",
	"CreditsMenu": "menus/credits/credits",
	"Freeplay": "menus/freeplay/freeplay",
	"MainMenu": "menus/main-menu/main-menu",
	"StoryMode": "menus/storymode/storymode",
	"TitleScreen": "menus/title-screen/title-screen",
	"Options": "menus/options/options"
}


var songsData={};
var weeksData={};

var week="";
var song="";
var mode="";
var cutscene="";
var songsQueue=[];
var storyMode=false;
var canChangeScene=true;

var uiSkin="default";
var scrollScale=1400.0;
var allowBotMode=false;
var botMode=false;

var prevScene="";
var tempData={};
var offsyncAllowed=30.0;
var engineVersion="1.0b";

func _ready():
	for i in getWeekList():
		var weekName=str(i).replace(".json","");
		var data=getWeekData(weekName);
		weeksData[weekName]=[false];
		for j in data.songs:
			songsData[j[0]]=[0,0,"?",0];
	
	if getGameSaveData()==null:
		saveGame();
		print("FIRST TIME PLAYING!");
	else:
		loadGame();

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_F4,KEY_F11] && !ev.echo && ev.pressed:
			OS.window_fullscreen=!OS.window_fullscreen;

func _process(dt):
	Engine.set_target_fps(Settings.fpsCap);
	OS.vsync_enabled=Settings.vsync;

func saveGame():
	var data={};
	data["settings"]={};
	data["weeksData"]=weeksData.duplicate(true);
	data["songsData"]=songsData.duplicate(true);
	for i in Settings.get_script().get_script_property_list():
		data["settings"][i.name]=Settings.get(i.name);
	var f=File.new();
	f.open("user://save.json",File.WRITE);
	f.store_line(to_json(data));
	f.close();
	printt("GAME SAVED!");
	
func loadGame():
	var f=File.new();
	var data=null;
	f.open("user://save.json",File.READ);
	data=parse_json(f.get_as_text());
	f.close();
	
	for i in data.settings.keys():
		Settings.set(i,data.settings[i]);
	for i in data.weeksData.keys():
		weeksData[i]=data.weeksData[i];
	for i in data.songsData.keys():
		songsData[i]=data.songsData[i];
	reloadKeys();
	printt("GAME LOADED!");
	
func deleteSave():
	var dir=Directory.new();
	dir.remove("user://save.json");
	
func changeScene(sceneName,useTrans=true,transTime=0.24,transInMask="vertical",transOutMask="inv-vertical",transSmoothSize=0.4):
	var path="res://source/%s.tscn"%[sceneName];
	prevScene=get_tree().current_scene.name;
	canChangeScene=false;
	if useTrans:
		Transition.fadeIn(transTime,transInMask,transSmoothSize);
		yield(Transition,"finished");
		get_tree().change_scene(path);
		yield(get_tree().create_timer(0.2),"timeout");
		Transition.fadeOut(transTime,transOutMask,transSmoothSize);
		yield(Transition,"finished");
		canChangeScene=true;
	else:
		get_tree().change_scene(path);
		canChangeScene=true;
	
func reloadScene(useTrans=true,transTime=0.24,transInMask="vertical",transOutMask="inv-vertical",transSmoothSize=0.4):
	canChangeScene=false;
	if useTrans:
		Transition.fadeIn(transTime,transInMask,transSmoothSize);
		yield(Transition,"finished");
		get_tree().reload_current_scene();
		yield(get_tree().create_timer(0.2),"timeout");
		Transition.fadeOut(transTime,transOutMask,transSmoothSize);
		yield(Transition,"finished");
		canChangeScene=true;
	else:
		get_tree().reload_current_scene();
		canChangeScene=true;

func reloadKeys():
	var noteInputs=["noteLeft","noteDown","noteUp","noteRight"];
	for i in len(noteInputs):
		var nKey=InputEventKey.new();
		nKey.set_scancode(Settings.noteKeys[i]);
		InputMap.action_erase_events(noteInputs[i]);
		InputMap.action_add_event(noteInputs[i],nKey);

func isWeekCompleted(weekName):
	if weekName=="":
		return true;
	return weeksData[weekName][0]==true;
	
func getCharacterList():
	var rawList=getFolderContent("source/gameplay/characters");
	var list=[];
	for i in rawList:
		var fName=str(i).replace(".tscn","");
		if !str(fName).ends_with(".gd"):
			list.append(fName);
	return list;

func getStageList():
	var rawList=getFolderContent("source/gameplay/stages");
	var list=[];
	for i in rawList:
		var fName=str(i).replace(".tscn","");
		if !str(fName).ends_with(".gd") && !str(fName)=="instances":
			list.append(fName);
	return list;

func getSongList():
	return songsData.keys();

func getWeekData(weekId):
	var f=File.new();
	f.open("res://assets/data/weeks/%s.json"%[weekId],File.READ);
	var data=parse_json(f.get_as_text());
	f.close();
	return data;
	
func getNoteTypeList():
	return getFileTxt("assets/data/notes");
	
func getEventsList():
	return getFileTxt("assets/data/events");

func getModes():
	return getFileTxt("assets/data/modes");

func getWeekList():
	return getFileTxt("assets/data/weeks");

func getUISkinList():
	return getFileTxt("assets/data/ui-skins");

func getCutsceneList():
	return getFileTxt("assets/data/cutscenes");

func getGameSaveData():
	var f:=File.new();
	var data=null;
	if f.file_exists("user://save.json"):
		f.open("user://save.json",File.READ);
		data=parse_json(f.get_as_text());
		f.close();
	return data;

func getFolderContent(path):
	var dir:=Directory.new()
	var files=[];
	if dir.open("res://"+path)==OK:
		dir.list_dir_begin()
		var fName=dir.get_next()
		while (fName!=""):
			if !dir.current_is_dir():
				files.append(fName);
			fName=dir.get_next()
	else:
		print("An error occurred when trying to access the path.");
	return files

func getFileTxt(path):
	var f=File.new();
	var data=[];
	f.open("res://"+path+".txt",File.READ);
	while not f.eof_reached():
		var line = f.get_line();
		data.append(line);
	f.close();
	return data;
