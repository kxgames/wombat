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
var units_in_game = {} # {unit : player_id}

var player_group_tags = {} # {player_id : {type : group_tag}}
# Example: player_group_tags = {
#		1 : {
#			'selectable': 'P1_selectable_objects',
#			'units' : 'P1_units',
#			'buildings' : 'P1_buildings',
#			...
#			}}

# Getters
func get_player_ids():
	return players_in_game.keys()

func get_other_players_ids(player_id):
	# Get the ids of everyone else but player_id
	var others = []
	for p_id in get_player_ids():
		if p_id != player_id:
			others.append(p_id)
	return others

func get_player_group_tag(player_id, tag_type):
	assert(tag_type in player_group_tags[player_id])
	return player_group_tags[player_id][tag_type]

func get_other_players_group_tags(player_id, tag_type):
	# Get the tags for everyone else but player_id
	var others_tag_list = []
	for other_id in get_other_players_ids(player_id):
		others_tag_list.append(get_player_group_tag(other_id, tag_type))
	return others_tag_list

func check_object_in_player_groups(object, player_id, tag_types):
	var in_required_groups = true
	for tag_type in tag_types:
		var tag = get_player_group_tag(player_id, tag_type)
		in_required_groups = in_required_groups and object.is_in_group(tag)
	return in_required_groups

# Setters?

# Setup and Creation
func _ready():
	pass # Replace with function body.

func create_player(player_id):
	var new_player = generic_player_scene.instance()
	new_player.setup(player_id)
	add_child(new_player)

	players_in_game[player_id] = new_player
	player_group_tags[player_id] = {
		'selectable' : 'P%d_selectable'%player_id,
		'units' : 'P%d_units'%player_id,
		}

	return new_player

func create_unit(unit_type, unit_position, player_id):
	var new_unit = unit_scene_lookup[unit_type].instance()
	new_unit.setup({
		"player" : players_in_game[player_id],
		"position" : unit_position,
		#"facing" : facing,
		})
	add_child(new_unit)

	new_unit.add_to_group(player_group_tags[player_id]['selectable'])
	new_unit.add_to_group(player_group_tags[player_id]['units'])
	units_in_game[new_unit] = player_id
	players_in_game[player_id].register_new_unit(new_unit)

	return new_unit

# Destruction
func delete_unit(dead_unit):
	var player_id = units_in_game[dead_unit]
	units_in_game.erase(dead_unit)
	players_in_game[player_id].deregister_dead_unit(dead_unit)

