extends Node

# The GameWorld is meant to store references to all the other in-game nodes like units, buildings, and players. It is not intended to do any game logic beyond setup.

export(PackedScene) var generic_player_scene
export(PackedScene) var swordsman_scene
export(PackedScene) var archer_scene
export(PackedScene) var cavalry_scene
onready var unit_scene_lookup = {
	'swordsman': swordsman_scene,
	'archer': archer_scene,
	'cavalry': cavalry_scene,
	}

var players_in_game = {} # {player_id : player}
var units_in_game = {} # {player_id : [units...]}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func create_player(player_id):
	var new_player = generic_player_scene.instance()
	new_player.setup(player_id)
	add_child(new_player)

	players_in_game[player_id] = new_player
	units_in_game[player_id] = []

	return new_player

func create_unit(unit_type, unit_position, player_id):
	var new_unit = unit_scene_lookup[unit_type].instance()
	new_unit.setup({
		"player" : players_in_game[player_id],
		"position" : unit_position,
		#"facing" : facing,
		})
	add_child(new_unit)

	units_in_game[player_id].append(new_unit)
	players_in_game[player_id].register_new_unit(new_unit)

	return new_unit

func get_player_ids():
	return players_in_game.keys()

func get_other_players_ids(player_id):
	var others = []
	for p_id in get_player_ids():
		if p_id != player_id:
			others.append(p_id)
	return others

