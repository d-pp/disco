extends Node
class_name DebugBoy

var frame: int = 0
var info: Dictionary = {}
var ui: Control = null

func _process(_delta):
	frame += 1

func print(label_name: String, value, frequency: int):
	if not info.has(label_name):
		var label = RichTextLabel.new()
		ui.add_child(label)
		info[label_name] = label
	info[label_name].text = str(value)
	if frame % frequency == 0:
		print(value)

func set_ui(this_is_a_local_variable_why_does_it_fucking_matter_if_it_shadows):
	self.ui = this_is_a_local_variable_why_does_it_fucking_matter_if_it_shadows
