extends "res://source/gameplay/notes/note.gd"

func _ready():
	modulate=Color.black.blend(Color(1,1,1,0.5));

func onHit():
	if isPlayer: setProperty("health",max(getProperty("health")-25,0));
	triggerEvent("playAnim","miss%s"%["Left","Down","Up","Right"][column],getCharacter())

func onHeld():
	pass

func onMiss():
	pass

func onHeldMiss():
	pass
