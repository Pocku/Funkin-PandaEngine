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

var isPlayer=false;
var pressed=false;
var holding=false;
var missed=false;

var character="";
var altAnim="";
var gfNote=false;
var strumline=null;

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
	
	if duration > 0.0:
		var lightColor = Color(1.0, 1.0, 1.0, 0.8)
		var darkColor = Color(0.8, 0.8, 0.8, 0.5)
		line.modulate = lerp(line.modulate, lightColor if holding else darkColor, 16.0*dt)
	
	if ms<=0.0 && duration>0.0 && pressed: updateLine();
	if ms<=0.0 && duration>0.0 && !holding: missTime+=dt;
	
func updateLine():
	var posY=(length*Game.scrollScale/scrollMult)-endHeight;
	line.points[1].y=max(posY,0.0);
	end.position.y=max(posY,0.0);
	end.scale.y=1.0-(abs(posY)/endHeight) if posY<=0.0 else 1.0;

func onHit():
	pressed = true
	holding = true
	
	if duration>0.0:
		texture=null;
		updateLine();
	if isPlayer: 
		setProperty("health",min(getProperty("health")+5,100));
		setProperty("comboTotal",getProperty("comboTotal")+1);
		callFunc("popUpScore",[time,column,duration,type,isPlayer]);
		callFunc("unMuffleSong");
	
	triggerEvent("charSetAltAnim",altAnim,character);
	triggerEvent("playCharAnim","sing%s"%["Left","Down","Up","Right"][column],character);
	triggerEvent("seekCharAnim",0.0,character);
	
	Game.emit_signal("noteHit",getData());
	
func onHeld():
	holding = true
	missTime = 0.0
	
	if isPlayer: setProperty("health",min(getProperty("health")+0.015,100));
	triggerEvent("charSetAltAnim",altAnim,character);
	triggerEvent("playCharAnim","sing%s"%["Left","Down","Up","Right"][column],character);
	if float(triggerEvent("getCharAnimTime",character))>0.08:
		triggerEvent("seekCharAnim",0.0,character);
	Game.emit_signal("noteHeld",getData());
	
func onMiss():
	missed = true
	
	if isPlayer: 
		setProperty("health",max(getProperty("health")-5,0));
		setProperty("score",getProperty("score")-100);
		setProperty("comboTotal",0);
		setProperty("misses",getProperty("misses")+1);
		callFunc("updateScoreLabel");
		callFunc("muffleSong");
	triggerEvent("charSetAltAnim",altAnim,character);
	triggerEvent("playCharAnim","miss%s"%["Left","Down","Up","Right"][column],character);
	triggerEvent("seekCharAnim",0.0,character);
	Game.emit_signal("noteMiss",getData());
	
func onHeldMiss():
	holding = false
	
	if isPlayer: setProperty("health",max(getProperty("health")-0.15,0));
	triggerEvent("charSetAltAnim",altAnim,character);
	triggerEvent("playCharAnim","miss%s"%["Left","Down","Up","Right"][column],character);
	triggerEvent("seekCharAnim",0.0,character);
	Game.emit_signal("noteHeldMiss",getData());
	
	
func callFunc(id,args=null):
	if args==null:
		return get_tree().current_scene.call(id);
	return get_tree().current_scene.call(id,args);

func triggerEvent(ev,arg1="",arg2=""):
	var events=getProperty("events");
	return events.onEvent(ev,arg1,arg2);

func setProperty(id,val):
	return get_tree().current_scene.set(id,val);

func getProperty(id):
	return get_tree().current_scene.get(id);

func getData():
	return {
		"time":time,
		"column":column,
		"duration":duration,
		"type":type,
		"isPlayer":isPlayer,
		"strumline":strumline
	}
