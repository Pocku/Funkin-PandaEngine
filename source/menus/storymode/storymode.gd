extends Node2D

onready var weekNameLabel=$WeekNameLabel;
onready var scoreLabel=$ScoreLabel;
onready var trackslabel=$TracksLabel;
onready var arrowLeft=$ArrowLeft;
onready var arrowRight=$ArrowRight;
onready var characters=$Characters;
onready var mode=$Mode;
onready var weeks=$Weeks;
onready var bg=$BG;
onready var tw=$Tween;

var weekOffsetY=118;
var weeksQueue=[];
var modesQueue=[];
var modeOpt=0;
var mainOpt=0;
var confirmed=false;

func _ready():
	weeks.position=Vector2(640,528);
	for i in [arrowLeft,arrowRight]:
		i.modulate=Color.cyan;
	
	var height=0.0;
	for i in Game.getWeekList():
		var data=Game.getWeekData(i);
		if data.hideStorymode: continue;
		var spr=Sprite.new();
		weeks.add_child(spr);
		spr.texture=load("res://assets/images/menus/storymode/weeks/%s.png"%[i])
		spr.position.y=height;
		weeksQueue.append(i);
		height+=weekOffsetY;
		
		if data.needWeek!="" && Game.weeksData[data.needWeek][0]==false: # Check if the needed week is finished
			var lockerIcon=Sprite.new();
			lockerIcon.texture=preload("res://assets/images/menus/storymode/lockerIcon.png");
			spr.add_child(lockerIcon);
			spr.self_modulate.a=0.0;
		
	onWeekChanged();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_DOWN,KEY_UP] && !confirmed:
				var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
				var oldMainOpt=mainOpt;
				mainOpt=clamp(mainOpt+dirY,0,len(weeksQueue)-1);
				if oldMainOpt!=mainOpt: onWeekChanged();
			
			if ev.scancode in [KEY_LEFT,KEY_RIGHT] && !ev.echo && ev.pressed && !confirmed:
				var dirX=int(ev.scancode==KEY_RIGHT)-int(ev.scancode==KEY_LEFT);
				var oldModeOpt=modeOpt;
				modeOpt=clamp(modeOpt+dirX,0,len(modesQueue)-1);
				if oldModeOpt!=modeOpt:
					var arrow=[arrowLeft,arrowRight][0 if dirX<0 else 1];
					tw.interpolate_property(arrow,"scale",Vector2.ONE*0.8,Vector2.ONE,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
					tw.interpolate_property(arrow,"modulate",Color.cyan.darkened(0.5),Color.cyan,0.12,Tween.TRANS_CUBIC,Tween.EASE_IN);
					tw.start();
					onModeChanged();
			
			if Game.canChangeScene && ev.scancode in [KEY_ESCAPE] && !confirmed:
				Game.changeScene("menus/main-menu/main-menu");
				confirmed=true;
			
			if Game.canChangeScene && ev.scancode in [KEY_ENTER] && !confirmed:
				var data=Game.getWeekData(weeksQueue[mainOpt]);
				var isUnlocked=Game.isWeekCompleted(data.needWeek);
				
				if isUnlocked:
					for i in data.songs:
						Game.songsQueue.append(i[0]);
					Game.storyMode=true;
					Game.week=weeksQueue[mainOpt];
					Game.song=Game.songsQueue[0];
					Game.mode=modesQueue[modeOpt];
					Game.changeScene("gameplay/gameplay");
					confirmed=true;
				else:
					var weekOpt=weeks.get_child(mainOpt);
					var shakeLen=8;
					while shakeLen>0:
						randomize();
						weekOpt.position.x=0+[-shakeLen,shakeLen][int(shakeLen)%2];
						yield(get_tree().create_timer(0.03),"timeout");
						shakeLen-=1;
					
func onWeekChanged():
	var data=Game.getWeekData(weeksQueue[mainOpt]);
	var isUnlocked=Game.isWeekCompleted(data.needWeek);
	
	var oldModes=modesQueue;
	modesQueue=["easy","normal","hard"];
	modeOpt=0;
	onModeChanged();

	for i in characters.get_children(): 
		if is_instance_valid(i): i.queue_free();
	
	if isUnlocked:
		weekNameLabel.text=str(data.name).to_upper();
		oldModes=modesQueue;
		modesQueue=data.modes;
		modeOpt=0;
		onModeChanged();
		
		trackslabel.text="";
		for s in data.songs:
			trackslabel.text+=str(s[0]).capitalize()+"\n";
			
		for i in len(data.characters):
			var charId=data.characters[i][0];
			var charPos=Vector2(data.characters[i][1],data.characters[i][2]);
			var charScale=Vector2.ONE*data.characters[i][3];
			var shouldFlip=data.characters[i][4] if len(data.characters[i])>4 else false;
			
			if charId in [""]: continue;
			var chara=load("res://source/menus/storymode/characters/%s.tscn"%[charId]).instance();
			characters.add_child(chara);
			chara.position=charPos;
			chara.scale=charScale;
			chara.scale.x*=[1,-1][int(shouldFlip)];
			chara.modulate=Color("#f9cf51");
	else:
		weekNameLabel.text="?";
		trackslabel.text="?";
		
	tw.interpolate_property(trackslabel,"modulate:a",0.0,1.0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(trackslabel,"rect_position:y",543+8,543,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(weekNameLabel,"modulate:a",0.0,1.0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(weekNameLabel,"rect_position:y",4,0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(weeks,"position:y",weeks.position.y,528-weekOffsetY*mainOpt,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	
	for i in weeks.get_child_count():
		weeks.get_child(i).modulate=Color.white if i==mainOpt else Color.darkgray;

func onModeChanged():
	mode.texture=load("res://assets/images/menus/storymode/modes/%s.png"%[modesQueue[modeOpt]]);
	tw.interpolate_property(mode,"modulate:a",0.0,1.0,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(mode,"position:y",511+8,511,0.24,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	
