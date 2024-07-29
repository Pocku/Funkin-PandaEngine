extends HBoxContainer

onready var lineEdit1 = $LineEdit
onready var lineEdit2 = $LineEdit2
onready var lineEdit3 = $LineEdit3

func setData(data):
	lineEdit1.text = data[0]
	lineEdit2.text = data[1]
	lineEdit3.text = data[2]

func getData():
	return [lineEdit1.text, lineEdit2.text, lineEdit3.text]
