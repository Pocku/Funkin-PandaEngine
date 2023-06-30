extends Node2D

onready var inst=$Inst;
onready var voices=$Voices;
onready var cam=$Cam;

onready var songTab={
	"song":$UI/Tabs/Song/Song/Song,
	"mode":$UI/Tabs/Song/Song/Mode,
	"stage":$UI/Tabs/Song/Song/Stage,
	"bpm":$UI/Tabs/Song/Timing/Bpm,
	"speed":$UI/Tabs/Song/Timing/Speed,
	"player1":$UI/Tabs/Song/Players/Player1,
	"player2":$UI/Tabs/Song/Players/Player2,
	"player3":$UI/Tabs/Song/Players/Player3
}
onready var sectionTab={
	"mustHitSection":$UI/Tabs/Section/MustHit,
	"altAnim":$UI/Tabs/Section/AltAnim,
	"gfSection":$UI/Tabs/Section/GfSection,
	"changeBPM":$UI/Tabs/Section/ChangeBPM,
	"bpm":$UI/Tabs/Section/Bpm,
	"sectionBeats":$UI/Tabs/Section/Beats
}

var chart={};
var noteAtlas=[];

var gridSize=40;
var curSection=0;
var strumTime=0.0;
var strumlineY=0.0;
var autoScroll=false;
var paused=false;
var offsyncAllowed=30.0;

func _ready():
	for i in ["purple","blue","green","red"]: 
		noteAtlas.append(load("res://assets/images/ui-skin/default/notes-types/normal/%s.png"%[i]));
	
	for i in sectionTab.keys():
		match sectionTab[i].get_class():
			"CheckBox": sectionTab[i].connect("toggled",self,"onSectionOptionChanged",[i]);
			"SpinBox": sectionTab[i].connect("value_changed",self,"onSectionOptionChanged",[i]);
			
	for i in ["easy","normal","hard"]: 
		songTab.mode.add_item(i);
		
	for i in Game.getSongList(): 
		songTab.song.add_item(i);
		
	for i in Game.stagesList: 
		songTab.stage.add_item(i);
		
	for i in [songTab.player1,songTab.player2,songTab.player3]:
		for c in Game.charactersList: 
			i.add_item(c);
	
	for i in Game.noteTypes:
		$UI/Tabs/Note/Type.add_item(i);
	
	for i in Game.eventType:
		$UI/Tabs/Event/Type.add_item(i);
	
	loadSong("black-sun","hard");
	Conductor.setBpm(chart.bpm);
	onSectionChanged();
	
	for i in [inst,voices]: i.play();
	cam.offset=Vector2(-11*gridSize,-720.0/2);
	
func _input(ev):
	if ev is InputEventMouseButton && paused:
		var yDir=int(ev.button_index==BUTTON_WHEEL_DOWN)-int(ev.button_index==BUTTON_WHEEL_UP);
		Conductor.time=clamp(Conductor.time+yDir*Conductor.stepCrochet/2.0,0.0,inst.stream.get_length())
	
	if ev is InputEventKey:
		if ev.scancode in [KEY_SPACE] && !ev.echo && ev.pressed:
			var old_paused=paused;
			paused=!old_paused;
			for i in [inst,voices]: i.stream_paused=paused;
			
		if ev.scancode in [KEY_A,KEY_D] && !ev.echo && ev.pressed:
			var xDir=int(ev.scancode==KEY_D)-int(ev.scancode==KEY_A);
			curSection=clamp(curSection+xDir,0,len(chart.notes));
			Conductor.time=getSectionStart(curSection);
			onSectionChanged();
		
func _process(dt):
	if !paused:
		Conductor.time=min(Conductor.time+dt,inst.stream.get_length());
		var time=(inst.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		if abs(time-Conductor.time)>(offsyncAllowed/1000.0):
			for i in [inst,voices]: i.seek(Conductor.time);
	
	var nextSect=getSection(Conductor.time);
	if nextSect!=curSection:
		curSection=nextSect;
		onSectionChanged();

	var sectStart=getSectionStart(curSection);
	var sectLenInSecs=chart.notes[curSection].sectionBeats*Conductor.crochet;
	strumTime=fmod(Conductor.time-sectStart,sectLenInSecs);
	strumlineY=getStrumY(strumTime if autoScroll else Conductor.time-sectStart);
	cam.position.y=strumlineY;
	update();
	
func _draw():
	if curSection>0: drawSection(curSection-1,-16*gridSize,[Color("d9d7d7").darkened(0.1),Color("e7e7e7").darkened(0.1)]);
	if curSection<len(chart.notes)-1: drawSection(curSection+1,16*gridSize,[Color("d9d7d7").darkened(0.13),Color("e7e7e7").darkened(0.1)]);
	drawSection(curSection,0,[Color("d9d7d7"),Color("e7e7e7")]);
	draw_line(Vector2(-1*gridSize,strumlineY),Vector2(8*gridSize,strumlineY),Color.white,3.0,false);

func drawSection(tSect,offsetY,gridColors):
	var sectData=chart.notes[tSect];
	var startTime=getSectionStart(tSect)*1000.0;
	
	drawGrid(offsetY,gridColors);
	draw_line(Vector2(4*gridSize,offsetY),Vector2(4*gridSize,offsetY+(16*gridSize)),Color.black,2.0,false);
	draw_line(Vector2(0,offsetY),Vector2(0,offsetY+(16*gridSize)),Color.black,2.0,false);
	
	for n in sectData.sectionNotes:
		var time=(n[0]-startTime)/1000.0;
		var dur=n[2]/1000.0;
		var column=int(n[1])%4;
		var tex=noteAtlas[column];
		var pos=Vector2(column*gridSize,getStrumY(time));
		var color=Color.white;
		var lenA=Vector2((n[1]*gridSize)+gridSize/2,round(getStrumY(time))+offsetY+gridSize/2);
		var lenB=Vector2((n[1]*gridSize)+gridSize/2,round(getStrumY(time+dur))+offsetY+gridSize/2);
		draw_texture_rect(tex,Rect2(pos+Vector2(0,offsetY),Vector2.ONE*gridSize),false,color);
		if n[2]>0.0: draw_line(lenA,lenB,Color.white,8.0);
	
func drawGrid(offsetY,colors):
	for x in range(-1,8): for y in 16:
		draw_rect(Rect2(x*gridSize,(y*gridSize)+offsetY,gridSize,gridSize),colors[(x+y)%2],true);

func loadSong(song,mode):
	var f=File.new();
	f.open("res://assets/data/%s/%s.json"%[song,mode],File.READ);
	chart=parse_json(f.get_as_text()).song;
	f.close();
	
	if !chart.has("player3"): chart["player3"]="gf";
	if !chart.has("cutscene"): chart["cutscene"]="";
	if !chart.has("stage"): chart["stage"]="stage";
	
	for i in len(chart.notes):
		if !chart.notes[i].has("gfSection"): chart.notes[i]["gfSection"]=false;
		if !chart.notes[i].has("sectionBeats"): chart.notes[i]["sectionBeats"]=4;
		if !chart.notes[i].has("altAnim"): chart.notes[i]["altAnim"]=false;
		if !chart.notes[i].has("changeBPM"): chart.notes[i]["changeBPM"]=false;
		if !chart.notes[i].has("bpm"): chart.notes[i]["bpm"]=100;
		for n in len(chart.notes[i].sectionNotes):
			if len(chart.notes[i].sectionNotes[n])<4:
				chart.notes[i].sectionNotes[n].append("");
	
	songTab.bpm.value=chart.bpm;
	songTab.speed.value=chart.speed;
	
	selectOptionButtonByName(songTab.stage,chart.stage);
	selectOptionButtonByName(songTab.player1,chart.player1);
	selectOptionButtonByName(songTab.player3,chart.player3);
	if !selectOptionButtonByName(songTab.player2,chart.player2):
		selectOptionButtonByName(songTab.player2,"dad");
	
	inst.stream=load("res://assets/songs/%s/Inst.ogg"%[song]);
	voices.stream=load("res://assets/songs/%s/Voices.ogg"%[song]);

func selectOptionButtonByName(opt:OptionButton,id):
	for i in opt.get_item_count():
		if opt.get_item_text(i)==id:
			opt.select(i);
			return true;
	return false;

func onSectionChanged():
	var sData=chart.notes[curSection];
	for i in sectionTab.keys():
		match sectionTab[i].get_class():
			"CheckBox": sectionTab[i].pressed=sData[i];
			"SpinBox": sectionTab[i].value=sData[i];

func onSectionOptionChanged(val,opt):
	chart.notes[curSection][opt]=val;
	if opt=="bpm" && chart.notes[curSection]["changeBPM"] || opt=="changeBPM":
		Conductor.setBpm(getLastBpm(curSection));

func getLastBpm(idx):
	var bpm=chart.bpm;
	var time=0.0;
	for i in range(0,idx+1):
		if chart.notes[i].changeBPM: 
			bpm=chart.notes[i].bpm
	return bpm;
	
func getSectionStart(index):
	var bpm=chart.bpm;
	var time=0.0;
	for i in range(0,index):
		if (chart.notes[i].changeBPM if chart.notes[i].has("changeBPM") else false):
			bpm=chart.notes[i].bpm
		var sectLen=chart.notes[i].lengthInSteps*((60.0/bpm)/4.0)
		time+=sectLen;
	return time;

func getSection(time):
	var bpm=chart.bpm
	var totalTime=0.0;
	for i in range(0,chart.notes.size()):
		if (chart.notes[i].changeBPM if chart.notes[i].has("changeBPM") else false):
			bpm=chart.notes[i].bpm;
		var sectLen=0.0;
		if chart.notes[i].has("sectionBeats"):
			sectLen=chart.notes[i].sectionBeats*(60.0/bpm);
		if totalTime+sectLen>time:
			return i;
		totalTime+=sectLen;
	return 0;

func getStrumTime(y):
	var timeLen=4*Conductor.crochet;
	return remapRange(y,0,0+(16*gridSize),0,timeLen);

func getStrumY(t):
	var timeLen=4.0*Conductor.crochet;
	return remapRange(t,0,timeLen,0,0+(16*gridSize)*1);

func remapRange(value,minA,maxA,minB,maxB):
	return(value-minB)/(maxA-minB)*(maxB-minB)+minB;
