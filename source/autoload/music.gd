extends Node

func _ready():
	pause_mode=Node.PAUSE_MODE_PROCESS;
	addMus("freaky");
	addMus("breakfast");
	addMus("gameover");
	addMus("gameover-end");

func addMus(id):
	var audio=AudioStreamPlayer.new();
	audio.name=id;
	audio.stream=load("res://assets/musics/%s.ogg"%[id]);
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

func stopAll():
	for i in get_child_count():
		while get_child(i).playing:
			get_child(i).stop();
