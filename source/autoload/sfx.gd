extends Node

func _ready():
	pause_mode=Node.PAUSE_MODE_PROCESS;
	for i in ["1","2","3","Go"]:
		addSfx("intro%s-%s"%[i,"default"]);
		addSfx("intro%s-%s"%[i,"pixel"]);

func addSfx(id):
	var audio=AudioStreamPlayer.new();
	audio.name=id;
	audio.stream=load("res://assets/sounds/%s.ogg"%[id]);
	add_child(audio);
	
func play(id,t=0.0):
	var audio=get_node(id);
	audio.play(t);
	return audio;

func stop(id):
	var audio=get_node(id);
	var time=audio.get_playback_position();
	audio.stop();
	return time;
