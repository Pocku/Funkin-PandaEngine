extends CanvasLayer

signal finished;

onready var rect=$Rect;
onready var tw=$Tween;

func fadeIn(time=0.3,mask="vertical",smoothSize=0.5):
	tw.remove(rect.get_material(),"shader_param/cutoff")
	rect.get_material().set("shader_param/mask",load("res://assets/images/transition-mask/%s.png"%[mask]));
	rect.get_material().set("shader_param/smoothSize",smoothSize);
	tw.interpolate_property(rect.get_material(),"shader_param/cutoff",rect.get_material().get("shader_param/cutoff"),0.0,time);
	tw.start();
	yield(tw,"tween_completed");
	emit_signal("finished");

func fadeOut(time=0.3,mask="inv-vertical",smoothSize=0.5):
	tw.remove(rect.get_material(),"shader_param/cutoff")
	rect.get_material().set("shader_param/mask",load("res://assets/images/transition-mask/%s.png"%[mask]));
	rect.get_material().set("shader_param/smoothSize",smoothSize);
	tw.interpolate_property(rect.get_material(),"shader_param/cutoff",rect.get_material().get("shader_param/cutoff"),1.0,time);
	tw.start();
	yield(tw,"tween_completed");
	emit_signal("finished");
