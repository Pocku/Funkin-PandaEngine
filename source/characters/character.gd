extends Node

onready var sprite=$Sprite;
onready var anims=$Sprite/Animations;

export var beatMult=1;

func _ready():
	Conductor.connect("beat",self,"onBeat");

func onBeat(beat):
	if int(beat)%beatMult==0:
		if getCurAnim()=="":
			playAnim("idle");
		elif getCurAnim()=="idle":
			seekAnim(0.0);

func playAnim(id):
	if anims.has_animation(id):
		anims.play(id);

func seekAnim(time):
	return anims.seek(time);

func getCurAnim():
	return anims.current_animation;

func getAnimTime():
	return anims.current_animation_position;
