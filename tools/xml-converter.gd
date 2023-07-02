extends Node2D

export var path="res://";
export var pathTo="res://";
export var sceneName="Node";
export var defaultSpeed=1.3;
export var centered=false;

var sprite=Sprite.new();
var animPlayer=AnimationPlayer.new();
var node=Node2D.new();

func _ready():
	var fps=0.05;
	var imageAtlas=getImageAtlas(path);
	add_child(node);
	sprite.centered=centered;
	sprite.texture=imageAtlas.tex;
	sprite.region_enabled=true;
	node.add_child(sprite);
	sprite.set_owner(node);
	sprite.add_child(animPlayer);
	animPlayer.set_owner(node);
	
	node.name=sceneName;
	sprite.name="Sprite";
	animPlayer.name="Animations";
	animPlayer.playback_speed=defaultSpeed;
	
	var prefixes=[];
	var anims={};
	
	#Define prefixes
	for f in imageAtlas.frames:
		var p=str(f.name).left(len(f.name)-3);
		if !p in prefixes:
			prefixes.append(p);
	
	#Load all frames to each specific animation
	for pfx in prefixes:
		anims[pfx]=[];
		for f in imageAtlas.frames:
			if str(f.name).begins_with(pfx):
				anims[pfx].append(f);
	
	for pfx in prefixes:
		var newAnim=Animation.new();
		var animData=anims[pfx];
		var trOffset=newAnim.add_track(Animation.TYPE_VALUE);
		var trRect=newAnim.add_track(Animation.TYPE_VALUE);
		
		newAnim.track_set_path(trOffset,":offset");
		newAnim.track_set_path(trRect,":region_rect");
		newAnim.length=len(animData)*fps;
		
		for i in len(animData):
			var f=animData[i];
			var fCrop=Rect2(f.x,f.y,f.width,f.height);
			var fPos=-Vector2(f.frameX,f.frameY)/(2 if centered else 1);
			
			newAnim.track_insert_key(trOffset,i*fps,fPos,0);
			newAnim.track_insert_key(trRect,i*fps,fCrop,0);
		animPlayer.add_animation(pfx,newAnim);
	
	var toSave=PackedScene.new();
	toSave.pack(node);
	ResourceSaver.save(pathTo+".tscn",toSave);
	printt("ATLAS CONVERTED!",pathTo+".tscn");
	
func getImageAtlas(p):
	var tex;
	var atlas;
	if ResourceLoader.exists(p+".png"):
		tex=load(p+".png")
		atlas=loadXML(p+".xml");
	return {"tex":tex,"frames":atlas}
	
func loadXML(p):
	var entries:=["name","width","height","frameX","frameY","x","y"]
	var file=XMLParser.new()
	var r=[]
	file.open(p)
	while file.read()==OK:
		if file.get_named_attribute_value_safe("name")!="":
			var d={};
			for i in entries:
				d[i]=file.get_named_attribute_value_safe(i);
			r.append(d);
	return r;
