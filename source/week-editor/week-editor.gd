extends Node2D

onready var notification = $Notification

onready var weekPath = $Tabs/Week/Content/Week/Path
onready var weekName = $Tabs/Week/Content/Name/LineEdit
onready var weekModes = $Tabs/Week/Content/Modes/LineEdit
onready var weekNeedWeek = $Tabs/Week/Content/NeedWeek/LineEdit
onready var weekCharacters = $Tabs/Week/Content/Characters/LineEdit
onready var weekBackground = $Tabs/Week/Content/WeekBackground/LineEdit
onready var weekHideOptions = $Tabs/Week/Content/HideOptions

onready var songsList = $Tabs/Songs/Scroll/Songs


var weekData = {}

func _ready():
	loadWeek()
	
func loadWeek():
	var file = File.new()
	file.open("res://assets/data/weeks/%s.json" % weekPath.text, File.READ)
	weekData = parse_json(file.get_as_text())
	file.close()
	onWeekLoaded()
	
func saveWeek():
	pass # Replace with function body.

func onWeekLoaded():
	weekName.text = weekData.name
	weekModes.text = arrayToString(weekData.modes)
	weekCharacters.text = arrayToString(weekData.characters)

func arrayToString(array):
	if array.size() > 0:
		var text = ""
		text += str(array[0])
		for i in range(1, array.size()):
			text += str(",", i)
		return text
	return ""
	
	
	
	
	
	
