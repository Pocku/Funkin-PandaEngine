extends Node2D

onready var options=$Options;
onready var cam=$Cam;
onready var bg=$BG;
onready var tw=$Tween;

var data={
	"graphics":[
		["low quality","lowQuality"],
		["shaders","useShaders"],
		["fps","fpsCap",[60,240,1]],
	],
	"gameplay":[
		["downscroll","downScroll"],
		["middlescroll","midScroll"],
		["ghost tapping","ghostTap"],
		["note splashes","noteSplashes"],
		["enemy notes","enemyNotes"],
		["hide hud","hideHud"],
		["show fps","showFps"]
	],
	"controls":[
		["keys","playerKeys"]
	]
}
var optionsQueue=[];
var offsetY=120;
var mainOpt=0;

func _ready():
	var height=-offsetY;
	options.position=Vector2(180,120);
	
	for k in data.keys():
		var group=Alphabet.new();
		group.text=k;
		group.position.y=height;
		group.position.x=-132;
		group.modulate=Color.whitesmoke.darkened(0.05);
		options.add_child(group);
		height+=offsetY;
		
		for i in data[k]:
			var opt=Alphabet.new();
			opt.text=str(i[0]);
			opt.position.y=height;
			options.add_child(opt);
			optionsQueue.append([opt,i,height]);
			height+=offsetY;
			
			match typeof(Settings.get(i[1])):
				TYPE_BOOL:
					var cb=preload("res://source/menus/check-box.tscn").instance();
					opt.add_child(cb);
					cb.position=Vector2(-70,4);
					cb.scale*=0.75;
					cb.get_node("Sprite/Animations").play("static" if Settings.get(i[1]) else "select")
				
				TYPE_INT:
					var sb=Alphabet.new();
					opt.add_child(sb);
					sb.text=str("<",Settings.get(i[1]),">");
					sb.position.x=opt.getWidth()+16.0;
					pass
			
		height+=offsetY*1.2;
	onOptionChanged();
	
func _input(ev):
	if ev is InputEventKey:
		if ev.scancode in [KEY_DOWN,KEY_UP] && !ev.echo && ev.pressed:
			var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
			var oldMainOpt=mainOpt;
			mainOpt=clamp(mainOpt+dirY,0,len(optionsQueue)-1);
			if oldMainOpt!=mainOpt: onOptionChanged();
		
		if ev.scancode in [KEY_ENTER] && !ev.echo && ev.pressed:
			onOptionPressed(optionsQueue[mainOpt]);
			#match typeof(Settings.get(i[1])):
		
func onOptionChanged():
	var targetY=(720/2)-optionsQueue[mainOpt][2];
	tw.interpolate_property(options,"position:y",options.position.y,targetY,0.32,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();

func onOptionPressed(data):
	var opt=data[0];
	var varId=data[1][1];
	
	match typeof(Settings.get(varId)):
		TYPE_BOOL:
			Settings.set(varId,!Settings.get(varId));
			var checkbox=opt.get_child(0);
			var anims=checkbox.get_node("Sprite/Animations");
			anims.play("static" if Settings.get(varId) else "select");
			tw.interpolate_property(opt,"scale",Vector2(1.2,0.7),Vector2.ONE,0.2,Tween.TRANS_CUBIC,Tween.EASE_OUT);
			tw.start();
	
	pass

