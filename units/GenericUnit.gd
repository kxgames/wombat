extends KinematicBody2D

onready var collision_flag_manager = get_node("/root/CollisionFlagManager")

var player
export var player_id:int
var is_selected = false
var movement_target : Vector2

export var unit_speed = 100
var group_speed = INF
var velocity :Vector2

func setup(unit_info):
	player = unit_info['player']
	player_id = player.player_id
	position = unit_info['position']

# Called when the node enters the scene tree for the first time.
func _ready():
	movement_target = position
	$SelectedSprite.hide()

	var player_color = player.player_color
	$WhiteBackground.self_modulate = player_color

	ready_collision_flags()

func ready_collision_flags():
	"""
	Overwrite all the collision flags for the unit body and melee zone.
	"""
	var other_ids = collision_flag_manager.get_other_players_ids(player_id)

	# Belongs to...

	# The unit body takes up physical space.
	collision_flag_manager.set_collision_layer(self, 'Unit_bodies', true)

	# The unit body belongs to one player but not others
	collision_flag_manager.set_player_layer(self, player_id, true)
	collision_flag_manager.set_player_layer(self, other_ids, false)

	# The melee zone belongs to no player and takes no physical space
	# (otherwise it will detect collisions with other melee zones)
	collision_flag_manager.set_player_layer($MeleeZone, [player_id] + other_ids, false)
	collision_flag_manager.set_collision_layer($MeleeZone, 'Unit_bodies', false)

	# Scans...

	# The unit body scans for collisions with other bodies
	collision_flag_manager.set_collision_mask(self, 'Unit_bodies', true)

	# The unit body does not scan for melee zones
	collision_flag_manager.set_player_mask(self, [player_id] + other_ids, false)

	# The melee zone only scans for unit bodies from other players
	# i.e. units ONLY attack units from other players
	collision_flag_manager.set_collision_mask($MeleeZone, 'Unit_bodies', false)
	collision_flag_manager.set_player_mask($MeleeZone, player_id, false)
	collision_flag_manager.set_player_mask($MeleeZone, other_ids, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(_delta):
	var gap = movement_target - position
	velocity = gap.normalized() * min(gap.length(), min(group_speed, unit_speed))
	var _velocity = move_and_slide(velocity)

func _on_GenericUnit_mouse_entered():
	# For now do nothing.... But this would be good for hovering information.
	if false:
		print("MouseEntered")
		print(position)

func update_unit_selection(new_is_selected):
	if not is_selected and new_is_selected:
		select_unit()
	elif is_selected and not new_is_selected:
		unselect_unit()

func select_unit():
	is_selected = true
	$SelectedSprite.show()

func unselect_unit():
	is_selected = false
	$SelectedSprite.hide()

func get_icon_scale():
	return $IconSprite.scale

func get_icon_texture():
	return $IconSprite.texture

func set_movement_target(new_target, slowest_speed=INF):
	movement_target = new_target
	group_speed = slowest_speed

func _on_MeleeZone_body_entered(body:Node):
	print(" Attack! ", body)
	assert(false)
