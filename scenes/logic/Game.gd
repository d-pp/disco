extends Node

# ~+'^'+~ LEVELS ~+'^'+~ #
const LVL_SANDBOX: String = "res://scenes/3d/levels/sandbox.tscn"

# ~+'^'+~ UI ~+'^'+~ #
const DEBUG_UI = "res://scenes/ui/debug_ui.tscn"

var level: Node3D
var debug_ui: Control

func _ready():
	level = load(LVL_SANDBOX).instantiate()
	add_child(level)
	debug_ui = load(DEBUG_UI).instantiate()
	add_child(debug_ui)
	

func _process(_delta):
	pass
