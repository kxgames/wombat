extends Node

# The Main is the root scene. It is resposible for setting up and holding references to the other major scenes (UI, GameWorld, etc.). It also (tbd) directs the high-level game logic between major scenes when needed (e.g. main menu to playing game).

# The code for initial players and units is here temporarily. It seems like it would be better in a godot resource(?) file of some kind. However, I don't understand how to use those yet.

onready var collision_flag_manager = get_node("/root/CollisionFlagManager")
onready var game_world = get_node("/root/GameWorld")

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

var init_unit_location_scaling = 150 # to scale the relative locations below
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

func _ready():
	# Create players and their initial set of units.
	for player_id in init_players:
		game_world.create_player(player_id)
		create_player_init_units(player_id)

func create_player_init_units(player_id):
	""" Create the initial set of units for a player. """

	# Get some info about the player
	var p_info = init_players[player_id]
	var base_position = p_info['base_position']
	var facing_angle = p_info['facing_angle']

	# Create all the units
	for unit_type in init_units:
		for loc in init_units[unit_type]:
			# Calculate the unit's position in world coordinates
			var direction = loc.rotated(facing_angle) 
			var relative_position = direction * init_unit_location_scaling
			var unit_position = base_position + relative_position

			var new_unit = game_world.create_unit(unit_type, unit_position, player_id)
			new_unit.connect("mouse_entered_unit",
				$ActionSelectionSystem, "_on_GenericUnit_mouse_entered_unit"
				)
			new_unit.connect("mouse_exited_unit", 
				$ActionSelectionSystem, "_on_GenericUnit_mouse_exited_unit"
				)


func _process(_delta):
	#collision_flag_manager.print_physics_layer_info()
	#assert(false)
	pass

