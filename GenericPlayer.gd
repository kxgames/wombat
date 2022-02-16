extends Node

export var player_id :int = 0

var unit_dict = {} # {unit : unit}

var player_color = null
var player_colors_lookup = {
	# See https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-colorn
	# See https://raw.githubusercontent.com/godotengine/godot-docs/master/img/color_constants.png
	1 : ColorN('limegreen'),
	2 : ColorN('gold'),
	3 : ColorN('firebrick'),
	4 : ColorN('royalblue'),
	}

func setup(p_id):
	player_id = p_id
	player_color = player_colors_lookup[p_id]

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func register_new_unit(new_unit):
	unit_dict[new_unit] = new_unit
