extends Node2D

onready var cam=getProperty("cam");
onready var tw=getProperty("tw");

func onEvent(evId,arg1,arg2):
	match evId:
		"addBeatZoom":
			cam.bumpScale-=float(arg1);
			
			pass


func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);
