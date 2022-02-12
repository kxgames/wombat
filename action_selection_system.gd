extends Node2D

var current_selection = []

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_SelectionBox_selection_finished():
	current_selection = $SelectionBox.get_current_selection()
	$ActionBox.update_selection(current_selection)
