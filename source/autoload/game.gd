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
var songsData={};
var weeksData={};

var week="";
var song="";
var mode="";
var songsQueue=[];
var storyMode=false;
var canChangeScene=true;

var uiSkin="default";
var scrollScale=1400.0;
var botMode=false;

func _ready():
	for i in getFileTxt("assets/data/weekList"):
		var weekName=str(i).replace(".json","");
		var data=getWeekData(weekName);
		weeksData[weekName]=[false];
		for j in data.songs:
			songsData[j[0]]=[0,0,false];
	
	if getGameSaveData()==null:
		saveGame();
		print("FIRST TIME PLAYING!")

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_F4,KEY_F11] && !ev.echo && ev.pressed:
			OS.window_fullscreen=!OS.window_fullscreen;

func _process(dt):
	OS.vsync_enabled=Settings.vsync;

func saveGame():
	var data={};
	data["settings"]={};
	data["weeks"]=weeksData.duplicate(true);
	data["songs"]=songsData.duplicate(true);
	for i in Settings.get_script().get_script_property_list():
		data["settings"][i.name]=Settings.get(i.name);
	var f=File.new();
	f.open("user://save.json",File.WRITE);
	f.store_line(to_json(data));
	f.close();
	printt("GAME SAVED!",data)
	
func changeScene(sceneName,useTrans=true,transTime=0.24,transInMask="vertical",transOutMask="inv-vertical",transSmoothSize=0.4):
	var path="res://source/%s.tscn"%[sceneName];
	get_tree().current_scene.set_process_input(false);
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
	var rawList=getFilesInFolder("source/gameplay/characters/");
	var list=[];
	for i in len(rawList): 
		if !str(rawList[i]).ends_with(".gd"):
			list.append(str(rawList[i]).replace(".tscn",""));
	list.push_front("");
	return list;

func getStageList():
	var list=getFilesInFolder("source/gameplay/stages/");
	for i in len(list): list[i]=str(list[i]).replace(".tscn","");
	return list;

func getSongList():
	return getFilesInFolder("assets/songs/");

func getWeekData(weekId):
	var f=File.new();
	f.open("res://assets/data/weeks/%s.json"%[weekId],File.READ);
	var data=parse_json(f.get_as_text());
	f.close();
	return data;

func getWeekList():
	var list=[];
	for i in getFileTxt("assets/data/weekList"):
		var weekName=str(i).replace(".json","");
		list.append(weekName);
	print(list)
	return list;

func getGameSaveData():
	var f:=File.new();
	var data=null;
	if f.file_exists("user://save.json"):
		f.open("user://save.json",File.READ);
		data=parse_json(f.get_as_text());
		f.close();
	return data;

func getFileTxt(path):
	var f=File.new();
	var data=[];
	f.open("res://"+path+".txt",File.READ);
	while not f.eof_reached():
		var line = f.get_line();
		data.append(line);
	f.close();
	return data;

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
