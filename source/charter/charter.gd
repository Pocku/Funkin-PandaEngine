extends Node2D

onready var inst=$Inst;
onready var timeLabel=$UI/TimeLabel;
onready var timeScroll=$UI/Tabs/TimeScroll;
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
	"player3":$UI/Tabs/Song/Players/Player3,
	"save":$UI/Tabs/Song/Options/Save,
	"load":$UI/Tabs/Song/Options/Load,
	"reload":$UI/Tabs/Song/Options/Reload
}
onready var sectionTab={
	"mustHitSection":$UI/Tabs/Section/MustHit,
	"altAnim":$UI/Tabs/Section/AltAnim,
	"gfSection":$UI/Tabs/Section/GfSection,
	"changeBPM":$UI/Tabs/Section/ChangeBPM,
	"bpm":$UI/Tabs/Section/Bpm,
	"sectionBeats":$UI/Tabs/Section/Beats
}
onready var noteTab={
	"root":$UI/Tabs/Note,
	"type":$UI/Tabs/Note/Type,
	"time":$UI/Tabs/Note/Timing/Time,
	"duration":$UI/Tabs/Note/Timing/Duration
}
onready var eventTab={
	"root":$UI/Tabs/Event,
	"type":$UI/Tabs/Event/Type,
	"arg1":$UI/Tabs/Event/Args/Arg1,
	"arg2":$UI/Tabs/Event/Args/Arg2,
	"add":$UI/Tabs/Event/Add,
	"sub":$UI/Tabs/Event/Sub,
	"next":$UI/Tabs/Event/Next,
	"prev":$UI/Tabs/Event/Prev,
	"pageLabel":$UI/Tabs/Event/PageLabel
}
var eventIcon=preload("res://assets/images/misc/event-icon.png");
var font=DynamicFont.new();

var chart={};
var noteAtlas=[];

var curEvent=-1;
var curNote=-1;
var eventPage=0;

var gridSize=40;
var curSection=0;
var strumTime=0.0;
var strumlineY=0.0;
var autoScroll=false;
var paused=false;
var offsyncAllowed=30.0;

var mouseGrid=Vector2();
var snapPrecise=false;

var charIcons={};

func _ready():
	Conductor.connect("bpmChanged",self,"onBpmChanged");
	Conductor.reset();
	
	font.font_data=preload("res://assets/fonts/vcr.ttf");
	font.outline_color=Color.black;
	font.outline_size=2;
	font.size=21;
	
	timeScroll.connect("scrolling",self,"onTimeScrollChanged");
	
	for i in 3: charIcons["player%s"%[i+1]]=load("res://assets/images/char-icons/no-icon.png");
	
	for i in ["purple","blue","green","red"]: 
		noteAtlas.append(load("res://assets/images/ui-skin/default/notes-types/default/%s.png"%[i]));
	
	for i in songTab.keys():
		match songTab[i].get_class():
			"OptionButton": songTab[i].connect("item_selected",self,"onSongOptionChanged",[i]);
			"SpinBox": songTab[i].connect("value_changed",self,"onSongOptionChanged",[i]);
			"Button": songTab[i].connect("pressed",self,"onSongOptionChanged",[true,i]);
	
	for i in eventTab.keys():
		match eventTab[i].get_class():
			"OptionButton": eventTab[i].connect("item_selected",self,"onEventOptionChanged",[i]);
			"LineEdit": eventTab[i].connect("text_changed",self,"onEventOptionChanged",[i]);
			"Button": eventTab[i].connect("pressed",self,"onEventOptionChanged",[true,i]);
			
	for i in sectionTab.keys():
		match sectionTab[i].get_class():
			"CheckBox": sectionTab[i].connect("toggled",self,"onSectionOptionChanged",[i]);
			"SpinBox": sectionTab[i].connect("value_changed",self,"onSectionOptionChanged",[i]);
	
	for i in noteTab.keys():
		match noteTab[i].get_class():
			"OptionButton": noteTab[i].connect("item_selected",self,"onNoteOptionChanged",[i]);
			"SpinBox": noteTab[i].connect("value_changed",self,"onNoteOptionChanged",[i]);
	
	for i in Game.getModes(): 
		songTab.mode.add_item(i);
		
	for i in Game.getSongList(): 
		songTab.song.add_item(i);
		
	for i in Game.getStageList(): 
		songTab.stage.add_item(i);
		
	for i in [songTab.player1,songTab.player2,songTab.player3]:
		for c in Game.getCharacterList(): 
			i.add_item(c);
	
	var noteTypes=Game.getNoteTypeList();
	for i in len(noteTypes):
		noteTab.type.add_item(("%s. %s"%[i,noteTypes[i]]) if i>0 else "");
	
	var eventList=Game.getEventsList();
	for i in eventList:
		eventTab.type.add_item(i);
	
	loadSong();
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
			
		if ev.scancode in [KEY_LEFT,KEY_RIGHT] && !ev.echo && ev.pressed:
			var xDir=int(ev.scancode==KEY_RIGHT)-int(ev.scancode==KEY_LEFT);
			curSection=clamp(curSection+xDir,0,len(chart.notes));
			Conductor.time=getSectionStart(curSection);
			onSectionChanged();
		
		if ev.scancode in [KEY_ESCAPE] && !ev.echo && ev.pressed:
			Game.changeScene("gameplay/gameplay")
		
		if ev.scancode in [KEY_SHIFT] && !ev.echo:
			snapPrecise=ev.pressed;
		
	if ev is InputEventMouseButton && paused:
		var mouseTime=getStrumTime(mouseGrid.y);
		var mouseColumn=int(mouseGrid.x/gridSize);
		
		if ev.button_index==BUTTON_LEFT && ev.pressed && isMouseInsideGrid():
			if int(mouseGrid.x/gridSize)>-1:
				var noteId=getNoteOverMouse(mouseTime,mouseColumn);
				if noteId!=-1: 
					chart.notes[curSection].sectionNotes.remove(noteId);
					noteId=-1;
				else: placeNote(mouseTime,mouseColumn);
			elif int(mouseGrid.x/gridSize)==-1:
				var evId=getEventOverMouse(mouseTime);
				if evId==-1: placeEvent(mouseTime);
				else: 
					chart.events.remove(evId);
					evId=-1;
			
		if ev.button_index==BUTTON_RIGHT && ev.pressed:
			if isMouseInsideGrid():
				if int(mouseGrid.x/gridSize)>-1:
					var noteId=getNoteOverMouse(mouseTime,mouseColumn);
					if noteId!=-1: onNoteSelected(chart.notes[curSection].sectionNotes[noteId],noteId);
					else: curNote=-1;
				elif int(mouseGrid.x/gridSize)==-1:
					var evId=getEventOverMouse(mouseTime);
					if evId!=-1: onEventSelected(evId);
					else: curEvent=-1;
			else:
				curNote=-1;	
				
func _process(dt):
	mouseGrid=(get_global_mouse_position()-(Vector2.ONE*gridSize)/2).snapped(Vector2(gridSize,gridSize if !snapPrecise else 1));
	
	if !paused:
		Conductor.time=min(Conductor.time+dt,inst.stream.get_length());
		if Conductor.time+0.1>inst.stream.get_length(): Conductor.time=0.0;
		var time=(inst.get_playback_position()+AudioServer.get_time_since_last_mix())-AudioServer.get_output_latency();
		if abs(time-Conductor.time)>(offsyncAllowed/1000.0):
			for i in [inst,voices]: i.seek(Conductor.time);
		timeScroll.value=Conductor.time/inst.stream.get_length();
	
	var nextSect=getSection(Conductor.time);
	if nextSect!=curSection:
		curSection=nextSect;
		onSectionChanged();

	var sectStart=getSectionStart(curSection);
	var sectLenInSecs=chart.notes[curSection].sectionBeats*Conductor.crochet;
	strumTime=fmod(Conductor.time-sectStart,sectLenInSecs);
	strumlineY=getStrumY(Conductor.time-sectStart);
	cam.position.y=strumlineY;

	noteTab.root.visible=curNote!=-1;
	eventTab.root.visible=curEvent!=-1;
	
	timeLabel.text=str("TIME: %s / %s \nSECTION: %s / %s\n\n'ESC' - PLAYTEST\n'ENTER' - EXIT EDITOR"%[str(stepify(Conductor.time,0.01)).pad_decimals(2),str(stepify(inst.stream.get_length(),0.01)).pad_decimals(2),curSection,len(chart.notes)]);
	update();
	
func _draw():
	drawGrid([Color("d9d7d7"),Color("e7e7e7")],[Color("d9d7d7").darkened(0.2),Color("e7e7e7").darkened(0.2)]);
	for i in range(-4 if curSection>0 else 0,8,1): 
		draw_line(Vector2(0,(i*4)*gridSize),Vector2(8*gridSize,(i*4)*gridSize),Color.gray,2.0);
	
	if curSection>0: drawSection(curSection-1,-16*gridSize);
	if curSection<len(chart.notes)-1: drawSection(curSection+1,16*gridSize);
	draw_line(Vector2(0,-(16*gridSize)),Vector2(0,(16*gridSize)*2),Color.black,2.0,false);
	draw_line(Vector2(4*gridSize,-(16*gridSize)),Vector2(4*gridSize,(16*gridSize)*2),Color.black,2.0,false);
	
	drawSection(curSection,0,true);
	drawEvents();
	draw_line(Vector2(-1*gridSize,strumlineY),Vector2(8*gridSize,strumlineY),Color.white,3.0,false);
	
	if isMouseInsideGrid(): draw_rect(Rect2(mouseGrid,Vector2.ONE*gridSize),Color(1,1,1,0.7));
	
	var mustHit=chart.notes[curSection].mustHitSection;
	var gfSection=chart.notes[curSection].gfSection;
	for i in 2:
		var pId="player%s"%[i+1];
		var icon=charIcons[pId];
		var sideLeft=-4*gridSize;
		var sideRight=9*gridSize;
		if pId=="player2" && !mustHit && gfSection || pId=="player1" && mustHit && gfSection: icon=charIcons["player3"];
		match pId:
			"player1": draw_texture_rect_region(icon,Rect2(sideLeft if mustHit else sideRight,strumlineY-32,64 if mustHit else -64,64),Rect2(0,0,icon.get_width()/2,icon.get_height()),Color.white);
			"player2": draw_texture_rect_region(icon,Rect2(sideLeft if !mustHit else sideRight,strumlineY-32,64 if !mustHit else -64,64),Rect2(0,0,icon.get_width()/2,icon.get_height()),Color.white);
	
			
func drawSection(tSect,offsetY,isMain=false):
	var sectData=chart.notes[tSect];
	var startTime=getSectionStart(tSect)*1000.0;
	
	for i in len(sectData.sectionNotes):
		var n=sectData.sectionNotes[i];
		if n[1]<0: continue;
		var time=(n[0]-startTime)/1000.0;
		var dur=n[2]/1000.0;
		var column=int(n[1]);
		var fColumn=int(n[1])%4;
		var tex=noteAtlas[fColumn];
		var pos=Vector2(column*gridSize,getStrumY(time));
		var color=Color.white;
		var lenA=Vector2((column*gridSize)+gridSize/2,round(getStrumY(time))+offsetY+gridSize/2);
		var lenB=Vector2((column*gridSize)+gridSize/2,round(getStrumY(time+dur))+offsetY+gridSize/2);
		draw_texture_rect(tex,Rect2(pos+Vector2(0,offsetY),Vector2.ONE*gridSize),false,color);
		
		if curNote!=-1 && curNote==i && isMain:
			draw_rect(Rect2(pos+Vector2(0,offsetY),Vector2.ONE*gridSize),Color.red,false,2);
				
		
		if getNoteTypeNumber(n[3])>0:
			var txSize=font.get_string_size(str(getNoteTypeNumber(n[3])));
			draw_string(font,pos+Vector2(0,offsetY)+Vector2((gridSize/2.0)-txSize.x/2.0,gridSize-txSize.y/2.0),str(getNoteTypeNumber(n[3])),Color.white);
		
		if n[2]>0.0: draw_line(lenA,lenB,Color.white,8.0);
		
		
func drawEvents():
	var startTime=getSectionStart(curSection)*1000.0;
	for i in len(chart.events):
		var e=chart.events[i];
		var time=(float(e[0])-startTime)/1000.0;
		var pos=Vector2(-1*gridSize,getStrumY(time));
		var color=Color.white;
		draw_texture_rect(eventIcon,Rect2(pos,Vector2.ONE*gridSize),false,color);
		
		if curEvent!=-1 && curEvent==i:
			draw_rect(Rect2(pos,Vector2.ONE*gridSize),Color.red,false,2);
		
		var txSize=font.get_string_size(str(len(e[1])));
		if len(e[1])>1:
			draw_string(font,pos+Vector2((gridSize/2.0)-txSize.x/2.0,gridSize-txSize.y/2.0),str(len(e[1])),Color.white);
		
func drawGrid(colors,darkColors):
	for x in range(-1,8): for y in range(-16 if curSection>0 else 0,32):
		var curColors=darkColors if y<0 || y>15 else colors;
		draw_rect(Rect2(x*gridSize,(y*gridSize),gridSize,gridSize),curColors[(x+y)%2],true);

func loadSong():
	var f=File.new();
	f.open("res://assets/data/songs/%s/%s.json"%[Game.song,Game.mode],File.READ);
	chart=parse_json(f.get_as_text()).song;
	f.close();
	
	if !chart.has("player3"): chart["player3"]="gf";
	if !chart.has("cutscene"): chart["cutscene"]="";
	if !chart.has("stage"): chart["stage"]="stage";
	if !chart.has("events"): chart["events"]=[];
	
	if !chart.stage in Game.getStageList(): chart.stage="stage";
	
	for i in len(chart.notes):
		if !chart.notes[i].has("gfSection"): chart.notes[i]["gfSection"]=false;
		if !chart.notes[i].has("sectionBeats"): chart.notes[i]["sectionBeats"]=4;
		if !chart.notes[i].has("altAnim"): chart.notes[i]["altAnim"]=false;
		if !chart.notes[i].has("changeBPM"): chart.notes[i]["changeBPM"]=false;
		if !chart.notes[i].has("bpm"): chart.notes[i]["bpm"]=100;
		for n in len(chart.notes[i].sectionNotes):
			if len(chart.notes[i].sectionNotes[n])<4:
				chart.notes[i].sectionNotes[n].append("");
			else:
				if typeof(chart.notes[i].sectionNotes[n][3])!=TYPE_STRING:
					chart.notes[i].sectionNotes[n][3]="";
			
	songTab.bpm.value=chart.bpm;
	songTab.speed.value=chart.speed;
	
	selectOptionButtonByName(songTab.song,Game.song);
	selectOptionButtonByName(songTab.mode,Game.mode);
	selectOptionButtonByName(songTab.stage,chart.stage);
	selectOptionButtonByName(songTab.player1,chart.player1);
	selectOptionButtonByName(songTab.player3,chart.player3);
	if !selectOptionButtonByName(songTab.player2,chart.player2):
		selectOptionButtonByName(songTab.player2,"dad");
	
	for i in 3: onCharChanged("player%s"%[i+1]);
	
	inst.stream=load("res://assets/songs/%s/Inst.ogg"%[Game.song]);
	voices.stream=load("res://assets/songs/%s/Voices.ogg"%[Game.song]);

func selectOptionButtonByName(opt:OptionButton,id):
	for i in opt.get_item_count():
		if opt.get_item_text(i)==id:
			opt.select(i);
			return true;
	return false;

func placeNote(time,column):
	var sectStart=getSectionStart(curSection)*1000.0;
	var noteData=[sectStart+(time*1000.0),column,0.0,Game.getNoteTypeList()[noteTab.type.selected]];
	chart.notes[curSection].sectionNotes.append(noteData);
	onNoteSelected(noteData,len(chart.notes[curSection].sectionNotes)-1);

func placeEvent(time):
	var evTypeId=eventTab.type.get_item_text(eventTab.type.selected);
	var sectStart=getSectionStart(curSection)*1000.0;
	var evData=[sectStart+(time*1000.0),[[evTypeId,eventTab.arg1.text,eventTab.arg2.text]]];
	chart.events.append(evData);
	onEventSelected(len(chart.events)-1);

func onNoteSelected(noteData,noteId):
	curNote=noteId;
	noteTab.time.value=noteData[0];
	noteTab.duration.value=noteData[2];
	
	var found=false;
	for i in len(Game.getNoteTypeList()):
		var typeId=("%s. %s"%[i,Game.getNoteTypeList()[i]]) if i>0 else "";
		if Game.getNoteTypeList()[i]==str(noteData[3]):
			selectOptionButtonByName(noteTab.type,typeId)
			return;
	selectOptionButtonByName(noteTab.type,"");
	printt("Note type not found!",noteData[3]);

func onEventSelected(evId):
	curEvent=evId;
	eventPage=0;
	onEventPageChanged();

func onEventPageChanged():
	var evPages=chart.events[curEvent][1];
	var evData=evPages[eventPage];
	eventTab.arg1.text=evData[1];
	eventTab.arg2.text=evData[2];
	eventTab.pageLabel.text="Page %s/%s"%[eventPage+1,len(evPages)];
	selectOptionButtonByName(eventTab.type,evData[0]);

func onBpmChanged():
	noteTab.time.step=(Conductor.stepCrochet/32.0)*1000.0;
	noteTab.duration.step=(Conductor.stepCrochet/32.0)*1000.0;

func onSectionChanged():
	var sData=chart.notes[curSection];
	for i in sectionTab.keys():
		match sectionTab[i].get_class():
			"CheckBox": sectionTab[i].pressed=sData[i];
			"SpinBox": sectionTab[i].value=sData[i];
	curNote=-1;
	curEvent=-1;
	eventPage=0;
	
func onSectionOptionChanged(val,opt):
	chart.notes[curSection][opt]=val;
	if opt=="bpm" && chart.notes[curSection]["changeBPM"] || opt=="changeBPM":
		Conductor.setBpm(getLastBpm(curSection));

func onEventOptionChanged(val,opt):
	var evId=eventTab.type.get_item_text(eventTab.type.selected);
	if curEvent!=-1:
		match opt:
			"type": chart.events[curEvent][1][eventPage][0]=evId;
			"arg1": chart.events[curEvent][1][eventPage][1]=val;
			"arg2": chart.events[curEvent][1][eventPage][2]=val;
			"add": 
				chart.events[curEvent][1].append(["","",""]);
				eventPage+=1;
				onEventPageChanged();
			"sub": 
				if len(chart.events[curEvent][1])>1:
					chart.events[curEvent][1].remove(eventPage);
					eventPage=max(eventPage-1,0);
					onEventPageChanged();	
			"next":
				eventPage=min(eventPage+1,len(chart.events[curEvent][1])-1);
				onEventPageChanged();
			"prev":
				eventPage=max(eventPage-1,0);
				onEventPageChanged();
		
func onSongOptionChanged(val,opt):
	match songTab[opt].get_class():
		"OptionButton": 
			if opt in ["player1","player2","player3"]: onCharChanged(opt);
			chart[opt]=songTab[opt].get_item_text(songTab[opt].selected);
			if opt=="song": Game.song=songTab[opt].get_item_text(songTab[opt].selected);
			if opt=="mode": Game.mode=songTab[opt].get_item_text(songTab[opt].selected);
			
		"Button": 
			match opt:
				"save":
					var f=File.new();
					var path="res://assets/data/songs/%s/%s.json"%[songTab.song.get_item_text(songTab.song.selected),songTab.mode.get_item_text(songTab.mode.selected)]
					f.open(path,File.WRITE);
					f.store_line(to_json({"song":chart}));
					f.close();
					printt("Chart saved!",path);
				"load":
					Game.song=songTab.song.get_item_text(songTab.song.selected);
					Game.mode=songTab.mode.get_item_text(songTab.mode.selected);
					get_tree().reload_current_scene();
					printt("Song loaded!",Game.song,Game.mode);
				"reload":
					get_tree().reload_current_scene();
					printt("Song reloaded!",Game.song,Game.mode);
				
		_: chart[opt]=val;
	if opt=="bpm": Conductor.setBpm(getLastBpm(curSection));
	
func onNoteOptionChanged(val,opt):
	if curNote!=-1:
		match opt:
			"type": chart.notes[curSection].sectionNotes[curNote][3]=Game.getNoteTypeList()[val];
			"time": chart.notes[curSection].sectionNotes[curNote][0]=val;
			"duration": chart.notes[curSection].sectionNotes[curNote][2]=val;

func onCharChanged(chara):
	var iconsPath="res://assets/images/char-icons/%s.png";
	var path=iconsPath%[songTab[chara].get_item_text(songTab[chara].selected)];
	var noIcon=load(iconsPath%["no-icon"]);
	charIcons[chara]=load(path) if ResourceLoader.exists(path) else noIcon;

func onTimeScrollChanged():
	Conductor.time=timeScroll.value*inst.stream.get_length();

func getNoteOverMouse(mouseTime,mouseColumn):
	var sectStart=getSectionStart(curSection)*1000.0;
	var timeY=round(getStrumY(mouseTime));
	
	for i in len(chart.notes[curSection].sectionNotes):
		var n=chart.notes[curSection].sectionNotes[i];
		var nTime=(n[0]-sectStart)/1000.0;
		var nColumn=int(n[1]);
		var nPosY=round(getStrumY(nTime));
		if nPosY==timeY && nColumn==mouseColumn:
			return i;
	return -1;

func getEventOverMouse(mouseTime):
	var sectStart=getSectionStart(curSection)*1000.0;
	var timeY=round(getStrumY(mouseTime));
	
	for i in len(chart.events):
		var ev=chart.events[i];
		var evTime=(ev[0]-sectStart)/1000.0;
		var evY=round(getStrumY(evTime));
		if evY==timeY:
			return i;
	return -1;

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
		var sectLen=chart.notes[i].sectionBeats*(60.0/bpm);
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

func getNoteTypeNumber(type):
	for i in len(Game.getNoteTypeList()):
		if Game.getNoteTypeList()[i]==type:
			return i;
	return 0;

func getStrumTime(y):
	var timeLen=4*Conductor.crochet;
	return remapRange(y,0,0+(16*gridSize),0,timeLen);

func getStrumY(t):
	var timeLen=4.0*Conductor.crochet;
	return remapRange(t,0,timeLen,0,0+(16*gridSize)*1);

func isMouseInsideGrid():
	var snap=mouseGrid/gridSize;
	return snap.x>-2 && snap.y>-1 && snap.y<16 && snap.x<8;

func remapRange(value,minA,maxA,minB,maxB):
	return(value-minB)/(maxA-minB)*(maxB-minB)+minB;
