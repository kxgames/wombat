extends Node2D

onready var game_world = get_node("/root/GameWorld")

var current_selection = []
var current_player_id = 1

func _ready():
	pass

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		if $ActionSubsystem.is_actuating:
			# Cancel the action first.
			$ActionSubsystem.reset()

			# Start a short timer to prevent multiple cancellation calls from 
			# a single quick press.
			$CancelationTimer.start()

		elif $CancelationTimer.time_left == 0:
			# Then cancel the selection if the continues to press cancel again.
			$SelectionSubsystem.reset()

func _on_unit_deleted(deleted_unit_id):
	game_world.debug_print('unit_death', ["AcSeS responding to unit death (id = ", deleted_unit_id, ")"])
	$SelectionSubsystem._on_unit_deleted(deleted_unit_id)
	$ActionSubsystem._on_unit_deleted(deleted_unit_id)

func _on_switch_player(player_id):
	current_player_id = player_id
	$ActionSubsystem.switch_player(player_id)
	$SelectionSubsystem.switch_player(player_id)
	current_selection = []

func _on_SelectionSubsystem_selection_finished():
	current_selection = $SelectionSubsystem.get_current_selection()
	$ActionSubsystem.update_selection(current_selection)

func _on_GenericUnit_mouse_entered_unit(unit):
	$ActionSubsystem.hovering_dict_add(unit)

func _on_GenericUnit_mouse_exited_unit(unit):
	$ActionSubsystem.hovering_dict_erase(unit)

