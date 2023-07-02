extends Sprite

var time=0.0;
var missTime=0.0;

var column=0;
var length=0.0;
var duration=0.0;
var isPlayer=false;

func _ready():
	var typeSkin="default";
	var noteTex=["purple","blue","green","red"][column];
	texture=load("res://assets/images/ui-skin/default/notes-types/%s/%s.png"%[typeSkin,noteTex]);

func _process(dt):
	var ms=(time+Conductor.waitTime)-Conductor.time;
	position.y=ms*Game.scrollScale;

func onHit():
	if isPlayer:
		setProperty("health",min(getProperty("health")+5,100));
	pass
	
func onHeld():
	pass
	
func onMiss():
	setProperty("health",max(getProperty("health")-0.01,0));
	pass
	
func onHeldMiss():
	pass

func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);
