extends Node2D

onready var bg=$BG;
onready var options=$Options;
onready var modeLabel=$Mode;
onready var scoreLabel=$Score;
onready var tw=$Tween;

var optionsOffsetY=145;
var modesQueue=[];
var songsQueue=[];
var mainOpt=0;
var modeOpt=0;
var curAccuracy=0.0;
var confirmed=false;

func _ready():
	var height=0.0;
	options.position=Vector2(80,720.0/2);
	
	for weekId in Game.getWeekList():
		var wData=getWeekData(weekId);
		if wData.hideFreeplay || wData.needWeek!="" && Game.weeksData[wData.needWeek][0]==false:
			continue;
		
		for rawData in wData.songs:
			var opt=Alphabet.new();
			var icon=Sprite.new();
			var author=Alphabet.new();
			
			opt.text=rawData[0];
			author.text=str("by ",rawData[2]);
			options.add_child(opt);
			
			author.scale*=0.26;
			author.position=Vector2(12,55)
			
			opt.add_child(icon);
			opt.add_child(author);
			
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
			if ev.scancode in [KEY_DOWN,KEY_UP] && !confirmed:
				var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
				var oldMainOpt=mainOpt;
				mainOpt=clamp(mainOpt+dirY,0,len(songsQueue)-1);
				if oldMainOpt!=mainOpt: onSongChanged();
			
			if ev.scancode in [KEY_LEFT,KEY_RIGHT] && !confirmed:
				var dirX=int(ev.scancode==KEY_RIGHT)-int(ev.scancode==KEY_LEFT);
				var oldModeOpt=modeOpt;
				modeOpt=clamp(modeOpt+dirX,0,len(modesQueue)-1);
				if oldModeOpt!=modeOpt: 
					onModeChanged();
					
		if Game.canChangeScene && ev.scancode in [KEY_ESCAPE] && !confirmed:
			Game.changeScene("menus/main-menu/main-menu");
			Sfx.play("menu-cancel");
			confirmed=true;
		
		if Game.canChangeScene && ev.scancode in [KEY_ENTER] && !confirmed:
			Game.storyMode=false;
			Game.song=songsQueue[mainOpt][0];
			Game.mode=modesQueue[modeOpt];
			Game.changeScene("gameplay/gameplay");
			Sfx.play("menu-ok");
			Music.stopAll();
			confirmed=true;

func _process(dt):
	scoreLabel.text="HIGHSCORE: /n%s (%s)"%[str(stepify(curAccuracy*100.0,0.1)).pad_decimals(1)+"%",Game.songsData[songsQueue[mainOpt][0]][2]];
	
			
func onSongChanged():
	Sfx.play("menu-scroll");
	modeOpt=0;

	for i in len(songsQueue):
		if i==mainOpt:
			var sData=songsQueue[i];
			modesQueue=sData[4];
			tw.interpolate_property(bg,"modulate",bg.modulate,Color(sData[3]),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
			onModeChanged();
			
	for i in options.get_child_count():
		var opt=options.get_child(i);
		var optAuthor=options.get_child(i).get_child(1);
	
		tw.interpolate_property(opt,"position:x",opt.position.x,48 if i==mainOpt else 0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		var dist=float(abs(mainOpt-i))/float(len(songsQueue));
		tw.interpolate_property(opt,"modulate:a",opt.modulate.a,lerp(1.0,0.0,dist),0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		tw.interpolate_property(opt,"self_modulate",opt.self_modulate,Color(songsQueue[mainOpt][3]) if i==mainOpt else Color.white,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
		tw.interpolate_property(optAuthor,"self_modulate",optAuthor.self_modulate,Color(songsQueue[mainOpt][3]) if i==mainOpt else Color.white,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	
	tw.interpolate_property(self,"curAccuracy",curAccuracy,Game.songsData[songsQueue[mainOpt][0]][1],0.32);
	tw.interpolate_property(options,"position",options.position,Vector2(240,(720/2)-40)-Vector2.DOWN*mainOpt*optionsOffsetY,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();

func onModeChanged():
	modeLabel.text=str("<",modesQueue[modeOpt],">");
	
	
func getWeekData(weekId):
	var f=File.new();
	f.open("res://assets/data/weeks/%s.json"%[weekId],File.READ);
	var data=parse_json(f.get_as_text());
	f.close();
	return data;
