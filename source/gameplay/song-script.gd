class_name SongScript extends Node2D

onready var scn=get_parent();
onready var stage=getProperty("stage");
onready var bf=getProperty("bf");
onready var dad=getProperty("dad");
onready var gf=getProperty("gf");
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

func camMoveTo(x,y,t=0.3):
	tw.interpolate_property(cam,"global_position",cam.global_position,Vector2(x,y),t,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT);
	tw.start();

func camZoomTo(zm,t=0.3):
	tw.interpolate_property(cam,"baseZoom",cam.baseZoom,zm,t,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT);
	tw.start();

func camRotateTo(rot,t=0.3):
	tw.interpolate_property(cam,"rotation",cam.rotation,rot,t,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT);
	tw.start();

func setProperty(path,val):
	scn.set(path,val);

func getProperty(path):
	return scn.get(path);
