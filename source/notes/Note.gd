extends Sprite

var time=0.0;
var column=0;
var length=0.0;
var duration=0.0;

func _ready():
	var typeSkin="default";
	var noteTex=["purple","blue","green","red"][column];
	texture=load("res://assets/images/ui-skin/default/notes-types/%s/%s.png"%[typeSkin,noteTex]);

func _process(dt):
	var ms=(time+Conductor.waitTime)-Conductor.time;
	position.y=ms*Game.scrollScale;
