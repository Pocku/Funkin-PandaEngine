extends Node2D

onready var bg=$BG;
onready var options=$Options;
onready var modeLabel=$Mode;
onready var authorLabel=$Author;
onready var scoreLabel=$Score;
onready var tw=$Tween;


var optionsOffsetY=120;
var modesQueue=[];
var songsQueue=[];
var mainOpt=0;
var modeOpt=0;
var confirmed=false;

func _ready():
	var height=0.0;
	options.position=Vector2(80,720.0/2);
	for weekId in Game.weeksList:
		var wData=getWeekData(weekId);
		for rawData in wData.songs:
			var opt=Alphabet.new();
			var icon=Sprite.new();
			opt.text=rawData[0];
			options.add_child(opt);
			opt.add_child(icon);
			opt.position.y=height;
			opt.position.x=0;
			icon.texture=load("res://assets/images/char-icons/%s.png"%[rawData[1]]);
			icon.hframes=2;
			icon.position.x=-78;
			icon.scale*=0.9;
			
			var sData=rawData.duplicate(true);
			sData.append(wData.modes);
			songsQueue.append(sData);
			height+=optionsOffsetY;
	onSongChanged();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_DOWN,KEY_UP]:
				var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
				var oldMainOpt=mainOpt;
				mainOpt=clamp(mainOpt+dirY,0,len(songsQueue)-1);
				if oldMainOpt!=mainOpt: onSongChanged();
			
			if ev.scancode in [KEY_LEFT,KEY_RIGHT]:
				var dirX=int(ev.scancode==KEY_RIGHT)-int(ev.scancode==KEY_LEFT);
				var oldModeOpt=modeOpt;
				modeOpt=clamp(modeOpt+dirX,0,len(modesQueue)-1);
				if oldModeOpt!=modeOpt: 
					onModeChanged();
					
		if Game.canChangeScene && ev.scancode in [KEY_ESCAPE] && !confirmed:
			Game.changeScene("menus/main-menu/main-menu")
			confirmed=true;
		
		if Game.canChangeScene && ev.scancode in [KEY_ENTER] && !confirmed:
			Game.song=songsQueue[mainOpt][0];
			Game.mode=modesQueue[modeOpt];
			Game.changeScene("gameplay/gameplay");
			confirmed=true;
			
func onSongChanged():
	modeOpt=0;
	authorLabel.text="by %s"%[songsQueue[mainOpt][2]]
	
	for i in len(songsQueue):
		if i==mainOpt:
			var sData=songsQueue[i];
			modesQueue=sData[4];
			tw.interpolate_property(bg,"modulate",bg.modulate,Color(sData[3]),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
			onModeChanged();
			
	for i in options.get_child_count():
		var opt=options.get_child(i);
		tw.interpolate_property(opt,"position:x",opt.position.x,48 if i==mainOpt else 0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		var dist=float(abs(mainOpt-i))/float(len(songsQueue)/4.0);
		tw.interpolate_property(opt,"modulate:a",opt.modulate.a,lerp(1.0,0.0,dist),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		tw.interpolate_property(opt,"self_modulate",opt.self_modulate,Color.white if i==mainOpt else Color.darkgray,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		
	tw.interpolate_property(options,"position",options.position,Vector2(240,(720/2)-40)-Vector2.DOWN*mainOpt*optionsOffsetY,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();

func onModeChanged():
	modeLabel.text=str("<",modesQueue[modeOpt],">");
	
	pass



func getWeekData(weekId):
	var f=File.new();
	f.open("res://assets/data/weeks/%s.json"%[weekId],File.READ);
	var data=parse_json(f.get_as_text());
	f.close();
	return data;
