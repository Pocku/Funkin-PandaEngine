extends Node2D

onready var sprite=$Sprite;
onready var anims=$Sprite/Animations;
onready var path=$Path;

var notes=[];
var ignoredNotes=[];
var noteSplash=null;
var column=0;

func _ready():
	noteSplash=load("res://source/gameplay/arrows/splashes/normal.tscn").instance();
	add_child(noteSplash);
	noteSplash.hide();
	playAnim("arrow");

func _physics_process(dt):
	noteSplash.scale=lerp(noteSplash.scale,Vector2.ONE*1.1,0.1);
	noteSplash.modulate.a=lerp(noteSplash.modulate.a,0.0,0.1);

func createSplash():
	if Settings.noteSplashes:
		noteSplash.get_node("Sprite/Animations").play("note impact %s %s0"%[1+(randi()%2),["purple","blue","green","red"][column]])
		noteSplash.show();
		noteSplash.scale=Vector2.ONE*1.0;
		noteSplash.modulate.a=2.0;

func playAnim(id):
	anims.play(str(column," ",id," 10"));

func seekAnim(time):
	return anims.seek(time);

func getCurAnim():
	return anims.current_animation;

func getAnimTime():
	return anims.current_animation_position;
