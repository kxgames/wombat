extends Node

export(PackedScene) var generic_player_scene
export(PackedScene) var swordsman_scene
export(PackedScene) var archer_scene
export(PackedScene) var cavalry_scene
onready var unit_scene_lookup = {
	'swordsman': swordsman_scene,
	'archer': archer_scene,
	'cavalry': cavalry_scene,
	}
onready var collision_flag_manager = get_node("/root/CollisionFlagManager")

var players_in_game = {} # {player_id : player}
var units_in_game = {} # {player_id : [units...]}

var init_players = {
	# {player_id : {players kwargs}}
	1 : {
		'base_position' : Vector2(200, 800), # world coordinates
		'facing_angle' : 0, # radians
		},
	2 : {
		'base_position' : Vector2(2200, 800), # world coordinates
		'facing_angle' : PI, # radians
		},
	}

var loc_scaling = 150 # to scale the relative locations
var init_units = {
	# {"type" : [relative_location, ...] }
	'swordsman' : [
		Vector2( 1, -1),
		Vector2( 1,  0),
		Vector2( 1,  1),
		],
	'archer' : [
		Vector2( 0, -1),
		Vector2( 0,  0),
		Vector2( 0,  1),
		],
	'cavalry' : [
		Vector2( 0,  2),
		Vector2( 0, -2),
		]
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_players()

func setup_players():
	collision_flag_manager.set_all_player_ids(init_players.keys())
	for p_id in init_players:
		# Create a new player
		var player = generic_player_scene.instance()
		player.setup(p_id)
		add_child(player)

		players_in_game[p_id] = player
		units_in_game[p_id] = []

		setup_player_init_units(p_id)

func setup_player_init_units(p_id):
	""" Create the initial set of units. """
	var p_info = init_players[p_id]
	var base_position = p_info['base_position']
	var facing_angle = p_info['facing_angle']

	for unit_type in init_units:
		for loc in init_units[unit_type]:
			# Calculate the unit's position in world coordinates
			var relative_position = loc.rotated(facing_angle) * loc_scaling
			var unit_position = base_position + relative_position

			var new_unit = unit_scene_lookup[unit_type].instance()
			new_unit.setup({
				"player" : players_in_game[p_id],
				"position" : unit_position,
				#"facing" : facing,
				})
			add_child(new_unit)

			units_in_game[p_id].append(new_unit)
			players_in_game[p_id].register_new_unit(new_unit)

func _process(_delta):
	#print_physics_layer_info()
	pass

func print_physics_layer_info():
	print()
	print("Physics layers for players: ", players_in_game.keys())
	var all_units = []
	for units_list in units_in_game.values():
		all_units += units_list
	for unit in all_units:
		print(" ", unit, " (p", unit.player.player_id, ") : ")
		print("  Layers: ", collision_flag_manager.get_player_layer(unit, players_in_game.keys()))
		print("  Masks: ", collision_flag_manager.get_player_mask(unit, players_in_game.keys()))
	assert(false)
