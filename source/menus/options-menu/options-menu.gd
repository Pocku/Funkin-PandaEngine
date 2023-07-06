extends Node2D

onready var keyMappingMenu=$KeyMapping;
onready var pressLabel=$KeyMapping/Label;
onready var options=$Options;
onready var cam=$Cam;
onready var bg=$BG;
onready var tw=$Tween;

var data={
	"graphics":[
		["low quality","lowQuality"],
		["shaders","useShaders"],
		["vsync","vsync"],
	],
	"gameplay":[
		["downscroll","downScroll"],
		["middlescroll","midScroll"],
		["ghost tapping","ghostTap"],
		["note splashes","noteSplashes"],
		["enemy notes","enemyNotes"],
		["hide hud","hideHud"],
		["show fps","showFps"]
	],
	"controls":[
		["note keys","noteKeys"]
	],
	"save-data":[
		["delete","delete"]
	]
}
var optionsQueue=[];
var offsetY=120;
var mainOpt=0;
var keyMapping=false;
var confirmed=false;

func _ready():
	var height=-offsetY;
	options.position=Vector2(180,120);
	keyMappingMenu.visible=false;
	
	for k in data.keys():
		var group=Alphabet.new();
		group.text=k;
		group.position.y=height;
		group.position.x=-132;
		group.modulate=Color.whitesmoke.darkened(0.05);
		options.add_child(group);
		height+=offsetY;
		
		for i in data[k]:
			var opt=Alphabet.new();
			opt.text=str(i[0]);
			opt.position.y=height;
			options.add_child(opt);
			optionsQueue.append([opt,i,height]);
			height+=offsetY;
			
			match typeof(Settings.get(i[1])):
				TYPE_BOOL:
					var cb=preload("res://source/menus/check-box.tscn").instance();
					opt.add_child(cb);
					cb.position=Vector2(-70,4);
					cb.scale*=0.75;
					cb.get_node("Sprite/Animations").play("static" if !Settings.get(i[1]) else "select")
				
				TYPE_INT:
					var sb=Alphabet.new();
					opt.add_child(sb);
					sb.text=str("<",Settings.get(i[1]),">");
					sb.position.x=opt.getWidth()+16.0;
					
				TYPE_ARRAY:
					var st=Alphabet.new();
					match i[1]:
						"noteKeys":
							var keysTx="";
							for j in Settings.get(i[1]):
								keysTx+=str(OS.get_scancode_string(j),",");
							keysTx=keysTx.left(len(keysTx)-1);
							st.text=keysTx;
							opt.add_child(st);
							st.position.x=52;
							st.position.y=75;
							st.scale*=0.7;
						
					
		height+=offsetY*1.2;
	onOptionChanged();
	
func _input(ev):
	if ev is InputEventKey:
		if optionsQueue[mainOpt][1][1]=="noteKeys" && ev.pressed && !ev.echo && keyMapping:
			var scancode=ev.scancode;
			if !scancode in Settings.noteKeys && !scancode in [KEY_ENTER,KEY_ESCAPE,KEY_F4,KEY_F11,KEY_MINUS,KEY_PLUS,KEY_KP_SUBTRACT,KEY_MINUS]:
				Settings.noteKeys.append(scancode);
			if len(Settings.noteKeys)>3:
				keyMapping=false;
				keyMappingMenu.hide();
				options.show();
				var keysTx="";
				for j in Settings.get(optionsQueue[mainOpt][1][1]):
					keysTx+=str(OS.get_scancode_string(j),",");
				keysTx=keysTx.left(len(keysTx)-1);
				optionsQueue[mainOpt][0].get_child(0).text=keysTx;
				Game.reloadKeys();

		if Game.canChangeScene && ev.scancode in [KEY_DOWN,KEY_UP] && !ev.echo && ev.pressed && !keyMapping:
			var dirY=int(ev.scancode==KEY_DOWN)-int(ev.scancode==KEY_UP);
			var oldMainOpt=mainOpt;
			mainOpt=clamp(mainOpt+dirY,0,len(optionsQueue)-1);
			if oldMainOpt!=mainOpt: onOptionChanged();
		
		if ev.scancode in [KEY_ENTER] && !ev.echo && ev.pressed && !keyMapping:
			onOptionPressed(optionsQueue[mainOpt]);
		
		if ev.scancode in [KEY_LEFT,KEY_RIGHT] && ev.pressed && !keyMapping:
			var dirX=int(ev.scancode==KEY_RIGHT)-int(ev.scancode==KEY_LEFT);
			onOptionScroll(optionsQueue[mainOpt],dirX);
		
		if ev.scancode in [KEY_ESCAPE] && !ev.echo && ev.pressed && !keyMapping && !confirmed:
			Game.changeScene("menus/main-menu/main-menu")
			confirmed=true;
			
		
func _process(dt):
	if len(Settings.noteKeys)<4:
		pressLabel.text=str("PRESS THE KEY\n\nYOU WANT FOR \n'%s'"%["NOTE LEFT","NOTE DOWN","NOTE UP","NOTE RIGHT",""][len(Settings.noteKeys)])
	
func onOptionChanged():
	var targetY=(720/2)-optionsQueue[mainOpt][2];
	tw.interpolate_property(options,"position:y",options.position.y,targetY,0.28,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	
	for i in len(optionsQueue):
		var opt=optionsQueue[i][0];
		opt.self_modulate=Color.white if i!=mainOpt else Color.crimson.lightened(0.2);
		tw.interpolate_property(opt,"position:x",-16 if i==mainOpt else 0.0,0.0,0.28,Tween.TRANS_CUBIC,Tween.EASE_OUT);
	tw.start();
	
func onOptionPressed(data):
	var opt=data[0];
	var varId=data[1][1];
	
	match typeof(Settings.get(varId)):
		TYPE_BOOL:
			Settings.set(varId,!Settings.get(varId));
			var checkbox=opt.get_child(0);
			var anims=checkbox.get_node("Sprite/Animations");
			anims.play("static" if !Settings.get(varId) else "select");
			tw.interpolate_property(opt,"scale",Vector2(1.05,0.9),Vector2.ONE,0.2,Tween.TRANS_CUBIC,Tween.EASE_OUT);
			tw.start();
	
		TYPE_ARRAY:
			match varId:
				"noteKeys":
					if !keyMapping:
						keyMapping=true;
						keyMappingMenu.visible=true;
						Settings.noteKeys=[];
						options.hide();
		
		TYPE_NIL:
			match varId:
				"delete":
					Game.deleteSave();
					var pid=OS.execute(OS.get_executable_path(),[],false);
					OS.kill(OS.get_process_id());
			
	
func onOptionScroll(data,dirX):
	var opt=data[0];
	var varId=data[1][1];
	
	match typeof(Settings.get(varId)):
		TYPE_INT,TYPE_REAL:
			var fMin=data[1][2][0];
			var fMax=data[1][2][1];
			var fStep=data[1][2][2];
			var curVal=Settings.get(varId);
			var spinbox=opt.get_child(0);
			Settings.set(varId,clamp(curVal+fStep*dirX,fMin,fMax));
			spinbox.text=str("<",Settings.get(varId),">");
			
	
