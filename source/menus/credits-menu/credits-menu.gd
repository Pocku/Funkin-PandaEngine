extends Node2D

onready var options=$Options;
onready var bg=$BG;
onready var tw=$Tween;

var creditsData={
	"Panda-Engine":[
		["Pockolas","pouko","#79e9d2","(aka uSauu, Pouko) Artist and Coder of Panda Engine"]
	],
	"Funkin'-Crew":[
		["ninjamuffin99","ninjamuffin","#d31b4f","Coder of FridayNightFunkin'"],
		["PhantomArcade","phantomarcade","#ffda33","Animator of FridayNightFunkin'"],
		["evilsk8r","evilsk8r","#7bda48","Artist of FridayNightFunkin'"],
		["kawaisprite","kawaisprite","#438bed","Composer of FridayNightFunkin'"]
	]
}
var membersQueue=[];
var memberOffsetY=150;
var mainOpt=0;
var confirmed=false;

func _ready():
	var height=0.0;
	options.position=Vector2(80,720/2);
	for k in creditsData.keys():
		var title=Alphabet.new();
		title.text=k;
		title.modulate=Color.gray;
		title.scale*=0.8;
		options.add_child(title);
		title.position.y=height;
		height+=memberOffsetY*0.8;
		
		for i in creditsData[k]:
			var opt=Alphabet.new();
			var icon=Sprite.new();
			var desc=Alphabet.new();
			
			opt.text=i[0];
			desc.text=i[3];
			
			options.add_child(opt);
			opt.position.x=190;
			opt.position.y=height;
			opt.add_child(icon);
			opt.add_child(desc);
			
			icon.texture=load("res://assets/images/credit-icons/%s.png"%[i[1]]);
			icon.position.x=-80;
			icon.scale*=0.8;
			
			desc.scale*=0.4;
			desc.position.x=8;
			desc.position.y=64;
			
			membersQueue.append([i,opt,desc,height]);
			height+=memberOffsetY;
			
			
			
		height+=memberOffsetY*1.2;
	onOptionChanged();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_DOWN,KEY_UP]:
				var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
				var oldMainOpt=mainOpt;
				mainOpt=clamp(mainOpt+dirY,0,len(membersQueue)-1);
				if oldMainOpt!=mainOpt: onOptionChanged();

			if Game.canChangeScene && ev.scancode in [KEY_ESCAPE] && !confirmed:
				Game.changeScene("menus/main-menu/main-menu");
				confirmed=true;

func onOptionChanged():
	var tgColor=Color(membersQueue[mainOpt][0][2]);
	
	for i in len(membersQueue):
		var opt=membersQueue[i][1];
		var optDesc=membersQueue[i][2];
		tw.interpolate_property(opt,"self_modulate",opt.self_modulate,tgColor if i==mainOpt else Color.white,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		tw.interpolate_property(optDesc,"self_modulate",optDesc.self_modulate,tgColor if i==mainOpt else Color.gray,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	
	tw.interpolate_property(bg,"modulate",bg.modulate,tgColor,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(options,"position:y",options.position.y,(720/2)-membersQueue[mainOpt][3],0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
