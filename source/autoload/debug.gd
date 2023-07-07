extends CanvasLayer

onready var label=$Label;

func _process(dt):
	label.text=str("FPS:%s \nWEEK:%s \nQUEUE:%s \nMODE:%s"%[Engine.get_frames_per_second(),Game.week,Game.songsQueue,Game.mode]);
	label.visible=Settings.showFps;
