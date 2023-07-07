extends CanvasLayer

onready var rect=$Rect;
onready var tw=$Tween;

func _ready():
	rect.modulate.a=0.0;

func start(time=0.24):
	tw.interpolate_property(rect,"modulate:a",1.0,0.0,time);
	tw.start();
	

