extends Sprite

onready var line=$Line;
onready var end=$Line/End;

var time=0.0;
var missTime=0.0;

var column=0;
var length=0.0;
var duration=0.0;

var pressed=false;
var held=false;
var missed=false;
var isPlayer=false;

func _ready():
	var typeSkin="default";
	var noteId=["purple","blue","green","red"][column];
	texture=load("res://assets/images/ui-skin/default/notes-types/%s/%s.png"%[typeSkin,noteId]);
	if duration>0.0:
		line.texture=load("res://assets/images/ui-skin/default/notes-types/%s/%s-%s.png"%[typeSkin,noteId,"hold"]);
		end.texture=load("res://assets/images/ui-skin/default/notes-types/%s/%s-%s.png"%[typeSkin,noteId,"end"])
		updateLine();
	else:
		line.queue_free();
	
func _process(dt):
	var ms=(time+Conductor.waitTime)-Conductor.time;
	position.y=ms*Game.scrollScale if !pressed else 0.0;
	length=max(length-dt,0.0) if ms<=0.0 else length;
	if ms<=0.0 && duration>0.0: updateLine();

func updateLine():
	var posY=(length*Game.scrollScale)-64.0;
	line.points[1].y=max(posY,0.0);
	end.position.y=max(posY,0.0);
	end.scale.y=1.0-(abs(posY)/64.0) if posY<=0.0 else 1.0;

func onHit():
	var player=getStrumsPlayer();
	pressed=true;
	if duration>0.0:
		texture=null;
		held=true;
		updateLine();
	if isPlayer: setProperty("health",min(getProperty("health")+5,100));
		
	var singDir="sing%s"%["Left","Down","Up","Right"][column];	
	player.playAnim(singDir);
	player.seekAnim(0.0);
	
func onHeld():
	held=true;
	if isPlayer: setProperty("health",min(getProperty("health")+0.015,100));
	
	var player=getStrumsPlayer();
	var singDir="sing%s"%["Left","Down","Up","Right"][column];	
	player.playAnim(singDir);
	if player.getAnimTime()>0.1:
		player.seekAnim(0.0);
	
func onMiss():
	missed=true;
	held=false;
	if isPlayer: 
		setProperty("health",max(getProperty("health")-5,0));
	
func onHeldMiss():
	held=false;
	if isPlayer: 
		setProperty("health",max(getProperty("health")-0.02,0));

func callFunc(id):
	return get_tree().current_scene.call(id);

func getStrumsPlayer():
	return get_parent().get_parent().get_parent().character;

func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);
