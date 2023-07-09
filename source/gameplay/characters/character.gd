class_name Character extends Node2D

onready var sprite=$Sprite;
onready var anims=$Sprite/Animations;

export var icon:Texture;
export var healthColor:Color;
export var camOffset=Vector2.ZERO;
export var flipped=false;
export var beatMult=1;
export var altAnim="";

func _ready():
	Conductor.connect("beat",self,"onBeat");

func onBeat(beat):
	if int(beat)%beatMult==0:
		if getCurAnim()=="":
			playAnim(str("idle",altAnim));
		elif getCurAnim()==str("idle",altAnim):
			seekAnim(0.0);

func playAnim(id):
	printt(id,altAnim)
	if anims.has_animation(str(id,altAnim)):
		anims.play(str(id,altAnim));

func seekAnim(time):
	return anims.seek(time);

func getCurAnim():
	return anims.current_animation;

func getAnimTime():
	return anims.current_animation_position;
