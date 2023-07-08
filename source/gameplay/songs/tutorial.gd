extends SongScript

func _ready():
	dad.global_position=Vector2(stage.gf.x,stage.gf.y);
	stage.move_child(bf,dad.get_index()+1);
