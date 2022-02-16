extends Node2D

var current_selection = []

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_SelectionBox_selection_finished():
	current_selection = $SelectionBox.get_current_selection()
	$ActionBox.update_selection(current_selection)

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		if $ActionBox.is_actuating:
			# Cancel the action first.
			$ActionBox.is_actuating = false
			$ActionBox.clear_ghost_list()

			# Start a short timer to prevent multiple cancellation calls from 
			# a single quick press.
			$CancelationTimer.start()

		elif $CancelationTimer.time_left == 0:
			# Then cancel the selection if the continues to press cancel again.
			$SelectionBox.is_selecting = false
			$SelectionBox.clear_existing_selection()

