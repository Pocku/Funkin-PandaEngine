extends Node2D

onready var trackslabel=$TracksLabel;
onready var modes=$Modes;
onready var weeks=$Weeks;
onready var bg=$BG;
onready var tw=$Tween;

func _ready():
	weeks.position=Vector2(640,528);
	
	modes.texture=preload("res://assets/images/menus/storymode-menu/modes/normal.png")
	
	var height=0.0;
	for i in Game.getWeekList():
		var spr=Sprite.new();
		weeks.add_child(spr);
		spr.texture=load("res://assets/images/menus/storymode-menu/weeks/%s.png"%[i])
		spr.position.y=height;
		height+=118;
		
