extends CanvasLayer

onready var label=$Label;

func _process(dt):
	label.text=str("FPS:%s"%[Engine.get_frames_per_second()]);
	label.visible=Settings.showFps;
