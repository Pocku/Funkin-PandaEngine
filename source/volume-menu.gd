extends CanvasLayer

onready var tab=$Tab;
onready var bar=$Tab/Bar;
onready var tw=$Tween;
onready var timer=$Timer;

func _ready():
	timer.connect("timeout",self,"onTimerEnd")
	setVolume(0.8);

func _input(ev):
	if ev is InputEventKey:
		if ev.pressed and !ev.echo:
			if ev.scancode in [KEY_KP_SUBTRACT,KEY_MINUS]:
				setVolume(Settings.volume-0.1);
			if ev.scancode in [KEY_KP_ADD,KEY_EQUAL]:
				setVolume(Settings.volume+0.1);

func setVolume(val):
	Settings.volume=clamp(val,0.0,1.0);
	bar.value=Settings.volume;
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),(-40.0+(40.0*Settings.volume)) if val>0.1 else -80.0);
	tab.rect_position.y=0.0;
	timer.start();
	
func onTimerEnd():
	tw.interpolate_property(tab,"rect_position:y",0,-60.0,0.3,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT);
	tw.start();
