extends Node2D

onready var options=$Options;
onready var bg=$BG;
onready var tw=$Tween;

var optionsList=["storymode","freeplay","options","credits"];
var optionsOffsetY=160;
var mainOpt=0;
var optionsHeight=0;
var confirmed=false;

func _ready():
	for i in optionsList:
		var opt=load("res://source/menus/main-menu/options/%s.tscn"%[i]).instance();
		options.add_child(opt);
		var anims=opt.get_node("Sprite/Animations");
		for a in anims.get_animation_list():
			anims.get_animation(a).loop=true;
		anims.play("idle");
		opt.position.y=optionsHeight;
		optionsHeight+=optionsOffsetY;
	options.position.x=1280/2.0;
	onMainOptionChanged();
	
func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_DOWN,KEY_UP] && !ev.echo && ev.pressed:
			var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
			var oldMainOpt=mainOpt;
			mainOpt=clamp(mainOpt+dirY,0,len(optionsList)-1);
			if oldMainOpt!=mainOpt: onMainOptionChanged();
		
		if Game.canChangeScene && ev.scancode in [KEY_ENTER] && !confirmed && !ev.echo && ev.pressed:
			confirmed=true;
			Game.changeScene([
				"menus/storymode/storymode",
				"menus/freeplay/freeplay",
				"menus/options/options",
				"menus/credits/credits"
			][mainOpt])
		
func onMainOptionChanged():
	var centerY=(720/2.0);
	var curOpt=options.get_child(mainOpt);
	tw.interpolate_property(options,"position:y",options.position.y,centerY-(optionsOffsetY*mainOpt),0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(bg,"position:y",bg.position.y,centerY-(8*mainOpt),0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(curOpt,"scale",Vector2.ONE*1.1,Vector2.ONE,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	for i in options.get_child_count():
		var optAnims=options.get_child(i).get_node("Sprite/Animations");
		optAnims.play("idle" if i!=mainOpt else "selected");
