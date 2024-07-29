extends Node2D

onready var sprite=$Sprite;
onready var anims=$Sprite/Animations;
onready var path=$Path;

var notes=[];
var ghostNotes=[];
var noteSplash=null;
var isPlayer = false
var column=0;

func _ready():
	noteSplash=load("res://source/gameplay/arrows/splashes/normal.tscn").instance();
	add_child(noteSplash);
	noteSplash.hide();
	playAnim("arrow");

func _physics_process(dt):
	if isPlayer: playerControls()
	else: botControls()
	updateNoteSplash()
	
func playerControls():
	var key = "note%s" % ["Left","Down","Up","Right"][column]
	var sucess = false
	
	if not notes.empty():
		var note = notes[0]
		var time = Conductor.time
		var duration = note.duration
		var ms = ((note.time + Conductor.waitTime) - time)
		var total_ms = ((note.time + note.duration + Conductor.waitTime) - time)
		
		if Input.is_action_just_pressed(key):
			if ms <= 0.16:
				note.onHit()
				sucess = true
				if note.duration == 0.0:
					note = killCurrentNote()
				playAnim("confirm")
		
		if Input.is_action_pressed(key):
			if note != null:
				if note.pressed and note.duration > 0.0:
					note.holding = true
					note.onHeld()
		else:
			if note != null:
				if ms <= -0.16 and note.duration > 0.0:
					note.holding = false
					if note.missTime >= 0.24:
						note.onHeldMiss()
				
		if note != null:
			if total_ms <= 0.0 and note.duration > 0.0:
				note = killCurrentNote()
		
		if note != null:
			if ms <= -0.16 and duration > 0.0 and not note.missed and not note.pressed:
				note.onMiss()

			if ms <= -0.16 and duration == 0.0 and not note.pressed:
				note.onMiss()
				note = killCurrentNote()
				
	
	if Input.is_action_just_pressed(key):
		if sucess: playAnim("confirm")
		else: playAnim("press")
	
	if Input.is_action_just_released(key):
		playAnim("arrow")



func botControls():
	if not notes.empty():
		var note = notes[0]
		var time = Conductor.time
		var duration = note.duration
		var ms = ((note.time + Conductor.waitTime) - time)
		var total_ms = ((note.time + note.duration + Conductor.waitTime) - time)
		
		if ms<=0.0 && not note.pressed:
			note.pressed=true;
			note.onHit();
			if note.duration==0.0:
				note.queue_free();
				notes.remove(0);
			else:
				note.texture=null;
				note.holding=true;
				
		if is_instance_valid(note):
			if note.duration>0.0 && note.holding:
				note.onHeld();
			if total_ms<=0.0 && note.duration>0.0:
				note.queue_free();
				notes.remove(0);
	

func killCurrentNote():
	var note = notes[0]
	note.queue_free()
	notes.remove(0)
	return null;

	
func updateNoteSplash():
	noteSplash.scale=lerp(noteSplash.scale,Vector2.ONE*1.1,0.1);
	noteSplash.modulate.a=lerp(noteSplash.modulate.a,0.0,0.1);


func createSplash():
	if Settings.noteSplashes:
		noteSplash.get_node("Sprite/Animations").play("note impact %s %s0"%[1+(randi()%2),["purple","blue","green","red"][column]])
		noteSplash.show();
		noteSplash.scale=Vector2.ONE*1.0;
		noteSplash.modulate.a=2.0;

func playAnim(id):
	anims.play(str(column," ",id," 10"));

func seekAnim(time):
	return anims.seek(time);

func getCurAnim():
	return anims.current_animation;

func getAnimTime():
	return anims.current_animation_position;
