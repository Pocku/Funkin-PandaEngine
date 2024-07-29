extends Node2D

func _ready():
	Game.song = "test"
	Game.mode = "hard"
	Game.allowBotMode = true
	Game.changeScene(Game.SCENES.TitleScreen);
