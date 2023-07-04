extends Camera2D

var baseZoom=1.0;
var bumpScale=0.0;

func _physics_process(dt):
	bumpScale=lerp(bumpScale,0.0,0.08);
	zoom=Vector2.ONE*(baseZoom+bumpScale);
