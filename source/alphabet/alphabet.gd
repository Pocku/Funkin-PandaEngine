class_name Alphabet extends Node2D

export(String,MULTILINE) var text="";
export var cutoff=-1;
export var charOffset=Vector2(48,80);
export var spaceWidth=48;
export var centered=false;
var chars="abcdefghijklmnopqrstuvwxyz0123456789:<>";
var tex={};

func _ready():
	for i in chars:
		var fChar=i;
		if fChar==":": fChar="colon";
		if fChar=="<": fChar="arrowLeft";
		if fChar==">": fChar="arrowRight";
		tex[i]=load("res://assets/images/alphabet/%s.png"%[fChar]);

func _physics_process(dt):
	update();
	
func _draw():
	var pos=Vector2();
	for i in range(0,len(text),1):
		var c=str(text[i]).to_lower();
		var c1=text[max(i-1,0)];
		var c2=text[min(i+1,len(text)-1)];
		if c=="/" && c2=="n":
			pos.x=0;
			pos.y+=charOffset.y;
			continue;
		if c1=="/":
			continue;
		if c==" ":
			pos.x+=spaceWidth
			continue;
		if not c in chars:
			continue;
		draw_texture(tex[c],pos+Vector2(0,-charOffset.y/2)-(Vector2(getWidth(),0)/2 if centered else Vector2()),Color.white);
		pos.x+=charOffset.x;
	
func getWidth():
	return (1+len(text))*charOffset.x;
	
func getHeight():
	return charOffset.y;
