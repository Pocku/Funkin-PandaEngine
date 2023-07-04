extends Node2D

var numbers=[];
var numOffset=90.0;

func _ready():
	scale*=0.72;
	match Game.uiSkin:
		"pixel": numOffset=10.0;
		_: numOffset=90.0;
	for i in 10: numbers.append(load("res://assets/images/ui-skin/%s/combo/%s.png"%[Game.uiSkin,str("num",i)]));
	
func _process(dt):
	update();
	
func _draw():
	var text=str(getProperty("comboTotal")).pad_zeros(3);
	var width=(len(text)*numOffset);
	for i in len(text):
		draw_texture(numbers[int(text[i])],Vector2((i*numOffset)-width/2,0),Color.white);

func getProperty(id):
	return get_tree().current_scene.get(id);
