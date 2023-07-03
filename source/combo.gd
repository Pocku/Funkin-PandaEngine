extends Sprite

onready var spawn=global_position;
onready var counter=$Counter;

var grav=8.0;
var vel=Vector2();
var jumpHeight=2.0;
var ratings={};

func _ready():
	for i in ["sick","good","bad","shit"]:
		ratings[i]=load("res://assets/images/ui-skin/%s/combo/%s.png"%[Game.uiSkin,i]);
	hide();

func _physics_process(dt):
	vel.y+=grav*dt;
	if global_position.y>1280: vel.y=0;
	global_position+=vel;
	modulate.a=lerp(modulate.a,0.0,0.08);

func setBaseScale(base):
	match Game.uiSkin:
		"pixel": scale=Vector2.ONE*6.0;
	scale*=base;
	counter.position=Vector2(0,55)/scale;

func pop(ratingId):
	texture=ratings[ratingId];
	global_position=spawn;
	vel.y=-jumpHeight;
	modulate.a=50.0;
	show();
