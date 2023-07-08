extends CanvasLayer

onready var player=$Player;

func _ready():
	player.connect("finished",self,"onFinished")
	player.stream=load("res://assets/videos/%s.webm"%[Game.cutscene]);
	player.play();

func onFinished():
	Game.emit_signal("cutsceneFinished");
	player.stream=null;
	queue_free();
