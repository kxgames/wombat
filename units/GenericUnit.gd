extends KinematicBody2D

signal mouse_entered_unit(unit)
signal mouse_exited_unit(unit)

onready var collision_flag_manager = get_node("/root/CollisionFlagManager")
onready var game_world = get_node("/root/GameWorld")

var player
export var player_id:int
var is_selected = false
var movement_target : Vector2

export var unit_speed = 100
var fighting_speed = 10
var group_speed = INF
var velocity :Vector2

var tracking_enemy:KinematicBody2D = null
var is_fighting = false

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
	var other_ids = game_world.get_other_players_ids(player_id)

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
	if tracking_enemy:
		set_movement_target(tracking_enemy.global_position, group_speed)
	var gap = movement_target - position
	var speed = min(gap.length(), min(group_speed, unit_speed))
	if is_fighting:
		speed = min(speed, fighting_speed)
	velocity = gap.normalized() * speed
	var _velocity = move_and_slide(velocity)

func _on_GenericUnit_mouse_entered():
	# Basically, resend the entered signal but with the unit as an argument
	# Some outside scenes need to know which unit the mouse is over
	emit_signal("mouse_entered_unit", self)

func _on_GenericUnit_mouse_exited():
	# Basically, resend the exited signal but with the unit as an argument
	# Some outside scenes need to know which unit the mouse is over
	emit_signal("mouse_exited_unit", self)

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

func get_body_shape():
	return $UnitBodyCollision.shape

func reset_tracking():
	tracking_enemy = null

func attack_enemy(new_tracking_enemy, slowest_speed=INF):
	set_movement_target(new_tracking_enemy.global_position, slowest_speed)
	tracking_enemy = new_tracking_enemy

func set_movement_target(new_target, slowest_speed=INF):
	movement_target = new_target
	group_speed = slowest_speed

func _on_MeleeZone_body_entered(body:Node):
	#is_fighting = true
	pass

func _on_MeleeZone_body_exited(body:Node):
	#is_fighting = false
	pass
