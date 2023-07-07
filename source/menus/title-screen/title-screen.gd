extends Node2D

onready var newgroundsLogo=$NewgroundsLogo;
onready var pressEnter=$PressEnter;
onready var strings=$Strings;
onready var logo=$Logo;
onready var gf=$GF;

var music=null;
var skipped=false;
var confirmed=false;

func _ready():
	Conductor.connect("beat",self,"onBeat");
	Conductor.reset();
	Conductor.setBpm(102);
	Music.stop("freaky");
	music=Music.play("freaky");
	strings.position=Vector2(1280/2.0,720/2.0);
	
	for i in [newgroundsLogo]:
		i.hide();
	for i in [gf,logo,pressEnter]:
		i.hide();

func _input(ev):
	if ev is InputEventKey:
		if !ev.echo && ev.pressed && !confirmed:
			if ev.scancode in [KEY_ENTER]:
				if skipped:
					Flash.start(0.32);
					Sfx.play("menu-ok");
					var pressEnterAnims=pressEnter.get_node("Sprite/Animations");
					pressEnterAnims.play("pressed");
					pressEnter.modulate=Color.white;
					confirmed=true;
					yield(get_tree().create_timer(0.4),"timeout");
					Game.changeScene("menus/main-menu/main-menu");
				if !skipped && Conductor.beatCount>1: skipIntro();

func _process(dt):
	var time=(music.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
	Conductor.time=min(Conductor.time+dt,music.stream.get_length());
	if Conductor.time>=music.stream.get_length():
		Conductor.time=0.0;
		music.seek(Conductor.time);
	if abs(time-Conductor.time)>(Game.offsyncAllowed/1000.0):
		music.seek(Conductor.time);

func onBeat(beat):
	var danceSide="dance%s"%(["Left","Right"][int(beat)%2]);
	var gfAnims=gf.get_node("Sprite/Animations");
	var logoAnims=logo.get_node("Sprite/Animations");
	gfAnims.play(danceSide);
	logoAnims.play("bump");
	logoAnims.seek(0.0);
	
	print(beat)
	
	if !skipped:
		match int(beat):
			1:
				addString("NINJAMUFFIN99");
				addString("PHANTOMARCADE");
				addString("KAWAISPRITE");
				addString("EVILSK8ER");
			3:
				addString("PRESENT");
			4:
				killStrings();
			5:
				addString("IN ASSOCIATION");
				addString("WITH");
			7:
				addString("NEWGROUNDS");
				strings.position.y-=180;
				newgroundsLogo.show();
			8:
				killStrings();
				newgroundsLogo.hide();
			9:
				addString(getRandomText());
			11:
				addString(getRandomText());
			12:
				killStrings();
			13:
				addString("FRIDAY");
			14:
				addString("NIGHT");
			15:
				addString("FUNKIN");
			16:
				if !skipped: skipIntro();

func skipIntro():
	Flash.start(0.5);
	skipped=true;
	for i in [newgroundsLogo,strings]:
		i.hide();
	for i in [gf,logo,pressEnter]:
		i.show();

func addString(rawText):
	var textArr=str(rawText).split("--");
	for tx in textArr:
		var string=Alphabet.new();
		string.centered=true;
		string.text=tx;
		strings.add_child(string);
		
		var totalHeight=(strings.get_child_count())*80;
		var stringHeight=80.0;
		string.position.y=totalHeight;
		strings.position.y=((720/2.0)-totalHeight/2.0)-stringHeight/2.0;

func killStrings():
	for i in strings.get_children(): 
		i.queue_free();

func getRandomText():
	randomize();
	var list=Game.getFileTxt("assets/data/intro-text");
	return list[randi()%(len(list)-1)]
	
