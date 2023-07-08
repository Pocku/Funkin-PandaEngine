extends Node2D

onready var cam=$Cam;
onready var tw=$Tween;

var music=null;
var character=null;
var musStarted=false;
var confirmed=false;
var timer=null;

func _ready():
	Conductor.connect("beat",self,"onBeat");
	Conductor.reset();
	Conductor.setBpm(100);
	
	Sfx.play("dies-%s"%[Game.uiSkin]);
	
	var data=Game.tempData;
	var charPath="res://source/gameplay/characters/%s-dead.tscn";
	character=load(charPath%[data.player[0]]).instance() if ResourceLoader.exists(charPath%[data.player[0]]) else load(charPath%["bf"]).instance();
	add_child(character);
	character.global_position=data.player[1];
	character.rotation=data.player[3];
	character.scale=data.player[2];
	
	var charAnims=character.get_node("Sprite/Animations");
	charAnims.play("dies");
	
	cam.global_position=data.cam[0];
	cam.rotation=data.cam[2];
	cam.zoom=data.cam[1];
	
	timer=get_tree().create_timer(2.9);
	yield(timer,"timeout");
	charAnims.play("idle");
	if !confirmed: music=Music.play("gameover");
	musStarted=true;
	tw.interpolate_property(cam,"zoom",cam.zoom,Vector2.ONE,0.5,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(cam,"position",cam.global_position,character.global_position+Vector2(0,-200),1.0,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT);
	tw.start();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed && !confirmed:
			if ev.scancode in [KEY_ENTER]:
				Sfx.stop("dies-%s"%[Game.uiSkin])
				confirmed=true;
				timer.emit_signal("timeout");
				onConfirmed();

func _process(dt):
	if musStarted && !confirmed:
		var time=(music.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		Conductor.time=min(Conductor.time+dt,music.stream.get_length());
		if Conductor.time>=music.stream.get_length():
			Conductor.time=0.0;
			Conductor.beatTime=0.0;
			music.seek(Conductor.time);
		if abs(time-Conductor.time)>(Game.offsyncAllowed/1000.0):
			music.seek(Conductor.time);

func onConfirmed():
	var charAnims=character.get_node("Sprite/Animations");
	Music.stopAll();
	Music.play("gameover-end");
	charAnims.play("confirm");
	yield(get_tree().create_timer(0.5),"timeout");
	Game.changeScene("gameplay/gameplay");

func onBeat(beat):
	if !confirmed:
		var charAnims=character.get_node("Sprite/Animations");
		charAnims.seek(0.0)
