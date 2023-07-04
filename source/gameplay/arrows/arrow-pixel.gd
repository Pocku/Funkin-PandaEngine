extends Node2D

onready var sprite=$Sprite;
onready var path=$Path;

var notes=[];
var column=0;

func _ready():
	scale*=8.5;
	playAnim("arrow");

func playAnim(id):
	sprite.play(str(column," ",id));

func seekAnim(time):
	sprite.frame=time;

func getCurAnim():
	return sprite.animation;

func getAnimTime():
	return sprite.frame;

