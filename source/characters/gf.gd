extends "res://source/characters/character.gd"

var danced=false;

func _ready():
	playAnim("danceLeft");

func onBeat(beat):
	danced=!danced;
	playAnim("dance%s"%["Left","Right"][int(danced)]);
	seekAnim(0.0);
