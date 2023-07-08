class_name Strums extends Node2D

var isPlayer=false;
var character=null;

func _ready():
	scale*=0.75;
	var w=0.0;
	for i in 4:
		var arrowPath="arrow";
		match Game.uiSkin:
			"pixel": arrowPath="arrow-pixel";
		var arrow=load("res://source/gameplay/arrows/%s.tscn"%[arrowPath]).instance();
		arrow.position.x=w;
		arrow.column=i;
		add_child(arrow);
		w+=161;
		if !isPlayer && Settings.midScroll:
			if i==1: w+=161*4.32

func _process(dt):
	for i in get_child_count():
		var arrow=get_child(i);
		var key="note%s"%(["Left","Down","Up","Right"][i]);
		if isPlayer && !Game.botMode: updateArrow(arrow,key);
		else: updateBotArrow(arrow);

func updateArrow(arrow,key):
	var justTap=true;
	if !arrow.notes.empty():
		var note=arrow.notes[0];
		var ms=(note.time+Conductor.waitTime)-Conductor.time;
		var totalMs=(note.time+note.duration+Conductor.waitTime)-Conductor.time;
		
		var canHit=ms<=0.16 && ms>-0.16 && note.duration==0.0 || ms<=0.16 && totalMs>0.0 && note.duration>0.0;
		var canMissLongNote=ms<-0.08 && totalMs>0.06;
		
		if ms<-0.16 && note.duration==0.0:
			if !note.pressed:
				note.onMiss();
				note.missed=true;
			note=killNote(arrow);
		
		if note!=null:
			if totalMs<=0.0 && note.duration>0.0:
				if !note.pressed:
					note.onMiss();
					note.missed=true;
				note=killNote(arrow);
				
		if !Input.is_action_pressed(key):
			if note!=null:
				if canMissLongNote && note.held:
					note.onMiss();
					note.held=false;
		else:
			if note!=null:
				if note.pressed:
					note.held=true;
		
		if Input.is_action_just_pressed(key) && canHit && note!=null:
			note.held=true;
			note.missTime=0.0;
			if !note.pressed:
				note.onHit();
				note.pressed=true;
				if note.duration==0.0:
					note=killNote(arrow);
			justTap=false;
		
		if note!=null:
			if note.duration>0.0:
				if note.held && note.pressed:
					note.onHeld();
					note.missTime=0.0;
					arrow.playAnim("confirm");
					if arrow.getAnimTime()>0.1:
						arrow.seekAnim(0.0);
				else:
					if canMissLongNote && note.missTime>0.13:
						note.onHeldMiss();
		
	if Input.is_action_just_pressed(key):
		arrow.playAnim("confirm" if !justTap else "press");
		if justTap && !Settings.ghostTap && getProperty("countdownStarted"):
			setProperty("health",max(getProperty("health")-1,0));
			setProperty("misses",getProperty("misses")+1);
			var singDir="miss%s"%[(["Left","Down","Up","Right"] if character.scale.x>0 else ["Right","Down","Up","Left"])[arrow.column]];	
			character.playAnim(singDir);
			character.seekAnim(0.0);
			callFunc("updateScoreLabel");
			callFunc("muffleSong");
			
	if !Input.is_action_pressed(key):
		arrow.playAnim("arrow");
			
func updateBotArrow(arrow):
	if !arrow.notes.empty():
		var note=arrow.notes[0];
		var ms=(note.time+Conductor.waitTime)-Conductor.time;
		var susMs=(note.time+note.duration+Conductor.waitTime)-Conductor.time;

		if ms<=0.0 && !note.pressed:
			note.pressed=true;
			note.onHit();
			if note.duration==0.0:
				note.queue_free();
				arrow.notes.remove(0);
			else:
				note.texture=null;
				note.held=true;
				
		if is_instance_valid(note):
			if note.duration>0.0 && note.held:
				note.onHeld();
			if susMs<=0.0 && note.duration>0.0:
				note.queue_free();
				arrow.notes.remove(0);
		
func killNote(arrow):
	arrow.notes[0].queue_free();
	arrow.notes.remove(0);
	return null;

func getWidth():
	return (get_child_count()-1)*161*scale.x;

func callFunc(id,args=null):
	if args==null:
		return get_tree().current_scene.call(id);
	return get_tree().current_scene.call(id,args);

func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);

