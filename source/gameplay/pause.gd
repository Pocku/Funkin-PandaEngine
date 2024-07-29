extends CanvasLayer

onready var songLabel=$SongLabel;
onready var modeLabel=$ModeLabel;
onready var deathsLabel=$DeathsLabel;
onready var canvasModulate = $CanvasModulate

onready var options=$Options;
onready var tw=$Tween;
onready var bg=$BG;

enum States {
	free,
	paused,
	sceneChanged
}

var state = States.free

var optionsList=["resume","restart song","botplay","settings","exit to menu"];
var canPause=false;
var slot=0;

func _ready():
	if !Game.allowBotMode:
		optionsList.remove(2);
	
	songLabel.text=str(Game.song).to_upper();
	modeLabel.text=str(Game.mode).to_upper();
	deathsLabel.text="BLUE-BALLED: %s"%[Game.songsData[Game.song][3]];
	canvasModulate.color.a = 0.0
	
	var totalHeight=0.0;
	for i in len(optionsList):
		var opt=Alphabet.new();
		opt.text=optionsList[i];
		opt.position.y=totalHeight;
		opt.centered=true;
		options.add_child(opt);
		totalHeight+=90;
	options.position=Vector2(1280/2,(720/2)-(totalHeight-120)/2);

func _process(dt):
	match state:
		States.paused:
			var oldSlot = slot
			if Input.is_action_just_pressed("ui_down"): slot += 1
			elif Input.is_action_just_pressed("ui_up"): slot -= 1
			slot = clamp(slot, 0, len(optionsList)-1);
			
			if slot != oldSlot:
				onOptionChanged();
			
			if Input.is_action_just_pressed("ui_accept"):
				match optionsList[slot]:
					"resume":
						state = States.free
						get_tree().paused = false
						fadeOut()
					
					"botplay":
						Game.botMode=!Game.botMode;
						Sfx.play("menu-scroll")
					
					"restart song":
						get_tree().paused = false
						Game.reloadScene()
						state = States.sceneChanged
						fadeOut()
						
					"settings":
						get_tree().paused = false
						state = States.sceneChanged
						Game.changeScene("menus/options/options");
						fadeOut()
						
					"exit to menu":
						get_tree().paused = false
						state = States.sceneChanged
						Game.changeScene("menus/%s/%s"%(["main-menu","main-menu"] if Game.storyMode else ["freeplay","freeplay"]));
						Music.play("freaky");

		States.free:
			if Input.is_action_just_pressed("ui_accept") and canPause:
				state = States.paused
				get_tree().paused = true
				fadeIn()
	
	for i in options.get_child_count():
		var option = options.get_child(i);
		var mainColor = Color.white;
		if optionsList[i] == "botplay":
			mainColor = Color.yellow if Game.botMode else Color.white;
		option.modulate = lerp(option.modulate, mainColor if i == slot else mainColor.darkened(0.6), 0.13);

func onOptionChanged():
	var option = options.get_child(slot);
	Sfx.play("menu-scroll")
	tw.interpolate_property(option, "scale", Vector2.ONE * 1.02, Vector2.ONE, 0.2, Tween.TRANS_CUBIC, Tween.EASE_OUT);
	tw.start();	

func fadeIn():
	tw.interpolate_property(canvasModulate, "color:a", canvasModulate.color.a, 1.0, 0.2 ,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.start()

func fadeOut():
	tw.interpolate_property(canvasModulate, "color:a", canvasModulate.color.a, 0.0, 0.2 ,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.start()
	
