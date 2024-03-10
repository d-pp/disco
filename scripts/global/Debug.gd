extends Node
class_name DebugBoy

var info: Dictionary = {}
var ui: Control = null

const TEXT_HEIGHT: int = 20
const TEXT_SIZE: int = 50

func _ready():
	info = {}

func log(label_name: String, value):
	self.print(label_name, value)

# don't look at this if you want to continue having a good day
func print(label_name: String, value):
	if not info.has(label_name):
		var neighbors: Array = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1), Vector2(0,0)]
		for i in range(5):
			var label: RichTextLabel = RichTextLabel.new()
			label.position = Vector2(10, info.size() / 5 * TEXT_HEIGHT) + neighbors[i]
			label.size = Vector2(1,30)
			label.clip_contents = false
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.bbcode_enabled = true
			if i < 4:
				info[label_name + "bg" + str(i+1)] = label
			else:
				info[label_name] = label
			ui.add_child(label)
	info[label_name + "bg1"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg2"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg3"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name + "bg4"].text = "[color=black]" + label_name + " : " + str(value)
	info[label_name].text = "[color=greenyellow]" + label_name + " : " + str(value)

func remove(label_name: String):
	if not info.has(label_name):
		return
	for i in range(5):
		var label: RichTextLabel
		if i < 4:
			label = info[label_name + "bg" + str(i+1)]
			info.erase(label_name + "bg" + str(i+1))
		else:
			label = info[label_name]
			info.erase(label_name)
		ui.remove_child(label)

func set_ui(debug_ui):
	self.ui = debug_ui
	ui.set_scale(Vector2(1.3,1.3))
