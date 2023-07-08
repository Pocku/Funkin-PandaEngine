extends CanvasLayer

onready var bg=$BG;
onready var textbox=$Textbox;
onready var portraits=$Portraits;
onready var textLabel=textbox.get_node("Sprite/Label");
onready var boxAnims=textbox.get_node("Sprite/Anims");
onready var canvasMod=$CanvasMod;
onready var tw=$Tween;

var textQueue=[];
var leftPort=null;
var rightPort=null;
var finished=false;
var oldSpeaker="";

func _ready():
	match Game.cutscene:
		_:
			addText("Hey you're pretty cute.","gf");
			addText("Use the arrow keys to keep up \nwith me singing.","gf");
	onPageChanged();
	
func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed:
			if ev.scancode in [KEY_ENTER] && !finished:
				if isTextFinished():
					var prevSpeaker=textQueue[0][1]
					textQueue.remove(0);
					if len(textQueue)==0:
						onFinished();
						finished=true;
					else:					
						var newSpeaker=textQueue[0][1];
						oldSpeaker=prevSpeaker if prevSpeaker!=newSpeaker else "";
						onPageChanged();
				else:
					skipText();

func skipText():
	textLabel.visible_characters=len(textLabel.bbcode_text)*10;

func onFinished():
	tw.interpolate_property(canvasMod,"color:a",1.0,0.0,0.5,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	yield(get_tree().create_timer(0.5),"timeout");
	Game.emit_signal("cutsceneFinished");
	queue_free();

func onPageChanged():
	var data=textQueue[0];
	textLabel.bbcode_text=data[0];
	textLabel.percent_visible=0.0;
	
	for i in portraits.get_children():
		if is_instance_valid(i): i.queue_free();
		
	if data[1]!="":
		var port=load("res://source/cutscenes/portraits/%s.tscn"%[data[1]]).instance();
		port.position=Vector2(1070,480);
		portraits.add_child(port);
		rightPort=port;
	
	if oldSpeaker!="":
		var port=load("res://source/cutscenes/portraits/%s.tscn"%[oldSpeaker]).instance();
		port.position=Vector2(220,480);
		portraits.add_child(port);
		port.scale.x*=-1;
		leftPort=port;
		port.modulate=Color.darkgray;
	
	tw.interpolate_property(rightPort,"position:y",480-7,480,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.interpolate_property(textbox,"scale",Vector2(1.05,0.95),Vector2.ONE,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	
	while textLabel.percent_visible<1.0:
		yield(get_tree().create_timer(0.04),"timeout");
		randomize();
		textLabel.visible_characters+=1;
		Sfx.play("type%s"%[int(randi()%3)]);

func isTextFinished():
	return textLabel.percent_visible>=1.0;

func addText(text,charId="",bubble="",speed=0.3):
	textQueue.append([text,charId,bubble,speed]);
