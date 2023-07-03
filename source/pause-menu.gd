extends CanvasLayer

onready var options=$Options;
onready var tw=$Tween;
onready var bg=$BG;

var optionsList=["resume","restart song","botplay","exit to menu"];
var canPause=false;
var paused=false;
var mainOpt=0;

var totalHeight=0.0;

func _ready():
	options.modulate.a=0.0;
	bg.modulate.a=0.0;
	for i in len(optionsList):
		var opt=Alphabet.new();
		opt.text=optionsList[i];
		opt.position.y=totalHeight;
		opt.centered=true;
		options.add_child(opt);
		totalHeight+=130;
	options.position=Vector2(1280/2,(720/2)-(totalHeight-120)/2);
	
func _input(ev):
	if ev is InputEventKey && canPause:
		if ev.scancode in [KEY_UP,KEY_DOWN] && !ev.echo && ev.pressed:
			var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
			var oldMainOpt=mainOpt;
			mainOpt=clamp(mainOpt+dirY,0,len(optionsList)-1);
			if oldMainOpt!=mainOpt:
				onOptionChanged();
			
		if ev.scancode in [KEY_ESCAPE,KEY_ENTER] && !ev.echo && ev.pressed:
			if !paused:
				pause(true);
				return;
				
			if ev.scancode==KEY_ENTER:
				match optionsList[mainOpt]:
					"resume":
						if paused: 
							pause(false);
							get_tree().current_scene.updateScoreLabel();
					"botplay":
						Game.botMode=!Game.botMode;
					"restart song":
						pause(false);
						get_tree().reload_current_scene();
					"exit to menu":
						pause(false);
						get_tree().quit();
					
func _physics_process(dt):
	for i in options.get_child_count():
		var opt=options.get_child(i);
		var mainColor=Color.white;
		if optionsList[i]=="botplay":
			mainColor=Color.yellow if Game.botMode else Color.white;
		opt.modulate=lerp(opt.modulate,mainColor if i==mainOpt else mainColor.darkened(0.6),0.13);

func onOptionChanged():
	var opt=options.get_child(mainOpt);
	tw.interpolate_property(opt,"scale",Vector2.ONE*1.02,Vector2.ONE,0.2,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();	

func pause(toggle):
	paused=toggle;
	get_tree().paused=paused;
	
	tw.interpolate_property(bg,"modulate:a",bg.modulate.a,[0.0,1.0][int(toggle)],0.2,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(options,"modulate:a",options.modulate.a,[0.0,1.0][int(toggle)],0.2,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();	
