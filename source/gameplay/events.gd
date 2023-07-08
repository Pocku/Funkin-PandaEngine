extends Node2D

onready var cam=getProperty("cam");
onready var tw=getProperty("tw");

func onEvent(evId,arg1,arg2):
	match evId:
		"addBeatZoom":
			cam.bumpScale-=float(arg1);

		"playAnim":
			var chara=getProperty(arg2);
			chara.playAnim(arg1);
		
		"seekAnim":
			var chara=getProperty(arg2);
			chara.seekAnim(float(arg1));
		
		"getAnimTime":
			var chara=getProperty(arg1);
			return chara.anims.current_animation_position;
		
		"getCurAnim":
			var chara=getProperty(arg1);
			return chara.anims.current_animation;
	return null;
	
func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);
