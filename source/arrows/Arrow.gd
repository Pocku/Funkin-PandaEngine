extends Node2D

onready var sprite=$Sprite;
onready var anims=$Sprite/Animations;
onready var path=$Path;

var notes=[];
var column=0;

func _ready():
	playAnim("arrow");

func playAnim(id):
	anims.play(str(column," ",id," 10"));

func seekAnim(time):
	return anims.seek(time);

func getCurAnim():
	return anims.current_animation;

func getAnimTime(id):
	return anims.current_animation_position;
