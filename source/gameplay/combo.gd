extends Sprite

onready var spawn=global_position;
onready var counter=$Counter;

var grav=10.0;
var vel=Vector2();
var jumpHeight=3.0;
var ratings={};

func _ready():
	match Game.uiSkin:
		"pixel": 
			scale=Vector2.ONE*7.0;
			counter.scale*=1.2;
	counter.position=Vector2(0,55)/scale;
	for i in ["sick","good","bad","shit"]:
		ratings[i]=load("res://assets/images/ui-skin/%s/combo/%s.png"%[Game.uiSkin,i]);
	hide();

func _physics_process(dt):
	vel.y+=grav*dt;
	if global_position.y>1280: vel.y=0;
	global_position+=vel;
	modulate.a=lerp(modulate.a,0.0,0.13);


func pop(ratingId):
	texture=ratings[ratingId];
	global_position=spawn;
	vel.y=-jumpHeight;
	modulate.a=24.0;
	show();
