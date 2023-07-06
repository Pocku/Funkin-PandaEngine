extends CanvasLayer

onready var label=$Label;

func _process(dt):
	label.text=str("FPS:%s \nQUEUE:%s \nMODE:%s"%[Engine.get_frames_per_second(),Game.songsQueue,Game.mode]);
	label.visible=Settings.showFps;
