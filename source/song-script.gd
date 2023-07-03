class_name SongScript extends Node2D

onready var scn=get_parent();
onready var cam=getProperty("cam");
onready var tw=getProperty("tw");

func _ready():
	Conductor.connect("beat",self,"onBeat");
	Game.connect("playerDied",self,"onPlayerDeath");
	Game.connect("noteHit",self,"onNoteHit");
	Game.connect("noteHeld",self,"onNoteHeld");
	Game.connect("noteMiss",self,"onNoteMiss");
	Game.connect("noteHeldMiss",self,"onNoteHeldMiss");

func onUpdatePost(dt):
	pass

func onEvent(evId,arg1,arg2):
	pass

func onSectionChanged(sectId,data):
	pass

func onSongStarted():
	pass

func onSongFinished():
	pass

func onCutsceneFinished():
	pass

func onCountdownStarted():
	pass

func onNoteHit(data):
	pass

func onNoteHeld(data):
	pass

func onNoteMiss(data):
	pass

func onNoteHeldMiss(data):
	pass

func onCountdownBeat(beat):
	pass

func onBeat(beat):
	pass

func onPlayerDeath():
	pass

func setProperty(path,val):
	scn.set(path,val);

func getProperty(path):
	return scn.get(path);
