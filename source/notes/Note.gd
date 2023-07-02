extends Sprite

onready var line=$Line;
onready var end=$Line/End;

var type="";
var time=0.0;
var missTime=0.0;
var scrollMult=1.0;
var endHeight=64;
var lineWidth=50;

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
	match Game.uiSkin:
		"pixel": 
			scrollMult=8.0;
			endHeight=6.0;
			lineWidth=7.0;
			end.offset.x=-7.5/2.0;
	
	texture=load("res://assets/images/ui-skin/%s/notes-types/%s/%s.png"%[Game.uiSkin,typeSkin,noteId]);
	if duration>0.0:
		line.width=lineWidth;
		line.texture=load("res://assets/images/ui-skin/%s/notes-types/%s/%s-%s.png"%[Game.uiSkin,typeSkin,noteId,"hold"]);
		end.texture=load("res://assets/images/ui-skin/%s/notes-types/%s/%s-%s.png"%[Game.uiSkin,typeSkin,noteId,"end"])
		line.modulate.a=0.7;
		line.scale.y=[1,-1][int(Settings.downScroll)];
		updateLine();
	else:
		line.queue_free();
	
	
func _process(dt):
	var ms=(time+Conductor.waitTime)-Conductor.time;
	position.y=ms*(Game.scrollScale*([1,-1][int(Settings.downScroll)])/scrollMult) if !pressed else 0.0;
	length=max(length-dt,0.0) if ms<=0.0 else length;
	if ms<=0.0 && duration>0.0: updateLine();

func updateLine():
	var posY=(length*Game.scrollScale/scrollMult)-endHeight;
	line.points[1].y=max(posY,0.0);
	end.position.y=max(posY,0.0);
	end.scale.y=1.0-(abs(posY)/endHeight) if posY<=0.0 else 1.0;

func onHit():
	var player=getStrumsPlayer();
	pressed=true;
	if duration>0.0:
		texture=null;
		held=true;
		updateLine();
	if isPlayer: 
		setProperty("health",min(getProperty("health")+5,100));
		setProperty("comboTotal",getProperty("comboTotal")+1);
		callFunc("popUpScore",[time,column,duration,type]);
		callFunc("unMuffleSong");
		
	var singDir="sing%s"%[(["Left","Down","Up","Right"] if player.scale.x>0 else ["Right","Down","Up","Left"])[column]];	
	player.playAnim(singDir);
	player.seekAnim(0.0);
	
func onHeld():
	held=true;
	if isPlayer: 
		setProperty("health",min(getProperty("health")+0.015,100));
		
	var player=getStrumsPlayer();
	var singDir="sing%s"%[(["Left","Down","Up","Right"] if player.scale.x>0 else ["Right","Down","Up","Left"])[column]];	
	player.playAnim(singDir);
	if player.getAnimTime()>0.1:
		player.seekAnim(0.0);
	callFunc("unMuffleSong");
	
func onMiss():
	missed=true;
	held=false;
	if isPlayer: 
		setProperty("health",max(getProperty("health")-5,0));
		setProperty("score",getProperty("score")-100);
		setProperty("comboTotal",0);
		setProperty("misses",getProperty("misses")+1);
		callFunc("updateScoreLabel");
		callFunc("muffleSong");
	
func onHeldMiss():
	held=false;
	if isPlayer: 
		setProperty("health",max(getProperty("health")-0.15,0));

func callFunc(id,args=null):
	if args==null:
		return get_tree().current_scene.call(id);
	return get_tree().current_scene.call(id,args);

func getStrumsPlayer():
	return get_parent().get_parent().get_parent().character;

func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);
