class_name Strums extends Node2D

var isPlayer=false;

func _ready():
	scale*=0.75;
	for i in 4:
		var arrowPath="res://source/arrows/Arrow.tscn";
		var arrow=load(arrowPath).instance();
		arrow.position.x=161*i;
		arrow.column=i;
		add_child(arrow);
