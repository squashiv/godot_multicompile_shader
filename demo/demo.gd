extends Control
var dict : Dictionary[String, Dictionary]

func _ready() -> void:
	var a : Dictionary = dict.get("")
	print(a)
