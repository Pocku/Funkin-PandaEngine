extends Node2D

onready var bg=$BG;
onready var options=$Options;
onready var tw=$Tween;

var optionsOffsetY=120;
var songsQueue=[];
var mainOpt=0;

func _ready():
	var height=0.0;
	options.position=Vector2(80,720.0/2);
	for weekId in Game.getWeekList():
		var wData=getWeekData(weekId);
		for sData in wData.songs:
			var opt=Alphabet.new();
			var icon=Sprite.new();
			opt.text=sData[0];
			options.add_child(opt);
			opt.add_child(icon);
			opt.position.y=height;
			opt.position.x=0;
			icon.texture=load("res://assets/images/char-icons/%s.png"%[sData[1]]);
			icon.hframes=2;
			icon.position.x=-78;
			icon.scale*=0.9;
			songsQueue.append(sData);
			height+=optionsOffsetY;
	onOptionChanged();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_DOWN,KEY_UP]:
				var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
				var oldMainOpt=mainOpt;
				mainOpt=clamp(mainOpt+dirY,0,len(songsQueue)-1);
				if oldMainOpt!=mainOpt: onOptionChanged();

func onOptionChanged():
	for i in len(songsQueue):
		if i==mainOpt:
			var sData=songsQueue[i];
			tw.interpolate_property(bg,"modulate",bg.modulate,Color(sData[2]),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		
	for i in options.get_child_count():
		var opt=options.get_child(i);
		tw.interpolate_property(opt,"position:x",opt.position.x,48 if i==mainOpt else 0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	
		var dist=float(abs(mainOpt-i))/float(len(songsQueue)-1);
		tw.interpolate_property(opt,"modulate:a",opt.modulate.a,lerp(1.0,0.0,dist),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		
	tw.interpolate_property(options,"position",options.position,Vector2(240,720/2.0)-Vector2.DOWN*mainOpt*optionsOffsetY,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	
func getWeekData(weekId):
	var f=File.new();
	f.open("res://assets/data/weeks/%s.json"%[weekId],File.READ);
	var data=parse_json(f.get_as_text());
	f.close();
	return data;
