extends Node
class_name DebugBoy

var frame: int = 0
var info: Dictionary = {}
var ui: Control = null

func _process(_delta):
	frame += 1

# don't ask me about this
func print(label_name: String, value):
	if not info.has(label_name):
		var label_bg = RichTextLabel.new()
		label_bg.position = Vector2(10 + 1, info.size() / 5 * 20)
		label_bg.size = Vector2(1,30)
		label_bg.clip_contents = false
		label_bg.autowrap_mode = false
		label_bg.bbcode_enabled = true
		info[label_name + "bg"] = label_bg
		ui.add_child(label_bg)
		
		var label_bg2 = RichTextLabel.new()
		label_bg2.position = Vector2(10 - 1, info.size() / 5 * 20)
		label_bg2.size = Vector2(1,30)
		label_bg2.clip_contents = false
		label_bg2.autowrap_mode = false
		label_bg2.bbcode_enabled = true
		info[label_name + "bg2"] = label_bg2
		ui.add_child(label_bg2)
		
		var label_bg3 = RichTextLabel.new()
		label_bg3.position = Vector2(10, info.size() / 5 * 20 - 1)
		label_bg3.size = Vector2(1,30)
		label_bg3.clip_contents = false
		label_bg3.autowrap_mode = false
		label_bg3.bbcode_enabled = true
		info[label_name + "bg3"] = label_bg3
		ui.add_child(label_bg3)
		
		var label_bg4 = RichTextLabel.new()
		label_bg4.position = Vector2(10, info.size() / 5 * 20 + 1)
		label_bg4.size = Vector2(1,30)
		label_bg4.clip_contents = false
		label_bg4.autowrap_mode = false
		label_bg4.bbcode_enabled = true
		info[label_name + "bg4"] = label_bg4
		ui.add_child(label_bg4)
		
		var label = RichTextLabel.new()
		label.position = Vector2(10, info.size() / 5 * 20)
		label.size = Vector2(1,30)
		label.clip_contents = false
		label.autowrap_mode = false
		label.bbcode_enabled = true
		info[label_name] = label
		ui.add_child(label)
	info[label_name + "bg"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg2"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg3"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg4"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name].text = "[color=white]" + label_name + " : " + str(value)

func set_ui(debug_ui):
	self.ui = debug_ui
