extends KinematicBody2D

signal mouse_entered_unit(unit)
signal mouse_exited_unit(unit)

onready var collision_flag_manager = get_node("/root/CollisionFlagManager")
onready var game_world = get_node("/root/GameWorld")

export var unit_name = "generic_unit"
var player
export var player_id:int

var is_selected = false
var movement_target : Vector2

export var unit_speed = 100
var fighting_speed = 10
var group_speed = INF
var velocity :Vector2

export var preferred_attack_type = 'melee'
var chasing_enemy_unit:KinematicBody2D = null
var attacking_enemies = {} # {enemy_unit : attack_type}
var attacked_by_enemies = {} # {enemy_unit : attack_type}
var is_retreating = false
var damage_lookup = {'melee' : 5.0} # {attack_type : damage_per_sec}

func dbg_print(debug_type, message, crash=false):
	game_world.debug_print(debug_type, message, crash)
func dbg_print_m(debug_type, messages, crash=false):
	game_world.debug_print_multiple(debug_type, messages, crash)

func setup(unit_info):
	player = unit_info['player']
	player_id = player.player_id
	position = unit_info['position']

# Called when the node enters the scene tree for the first time.
func _ready():
	ready_collision_flags()
	add_to_group(unit_name)
	engagement_zone_deactivate('melee')
	disengagement_zone_deactivate('melee')

	reset_movement_target()

	# Hide/disable things not needed at the start
	$SelectedSprite.hide()
	$HealthBarPosition.hide()
	var player_color = player.player_color
	$WhiteBackground.self_modulate = player_color


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

	# The melee zones belongs to no player and takes no physical space
	# (otherwise it will detect collisions with other melee zones)
	collision_flag_manager.set_player_layer($MeleeZoneEngage, [player_id] + other_ids, false)
	collision_flag_manager.set_player_layer($MeleeZoneDisengage, [player_id] + other_ids, false)
	collision_flag_manager.set_collision_layer($MeleeZoneEngage, 'Unit_bodies', false)
	collision_flag_manager.set_collision_layer($MeleeZoneDisengage, 'Unit_bodies', false)

	# Scans...

	# The unit body scans for collisions with other bodies
	collision_flag_manager.set_collision_mask(self, 'Unit_bodies', true)

	# The unit body does not scan for melee zones
	#collision_flag_manager.set_player_mask(self, [player_id] + other_ids, false)

	# The melee zone only scans for unit bodies from other players
	# i.e. units only attack units from other players
	collision_flag_manager.set_collision_mask($MeleeZoneEngage, 'Unit_bodies', false)
	collision_flag_manager.set_collision_mask($MeleeZoneDisengage, 'Unit_bodies', false)
	collision_flag_manager.set_player_mask($MeleeZoneEngage, player_id, false)
	collision_flag_manager.set_player_mask($MeleeZoneDisengage, player_id, false)
	collision_flag_manager.set_player_mask($MeleeZoneEngage, other_ids, true)
	collision_flag_manager.set_player_mask($MeleeZoneDisengage, other_ids, true)

	# Debug printing
	dbg_print_m('collision_flags', [
		["Player ids: ", game_world.get_player_ids()],
		'',
		["Player layer name: ", collision_flag_manager.get_layer_names(player_id)],
		["Others layer names: ", collision_flag_manager.get_layer_names(other_ids)],
		'',
		collision_flag_manager.print_bitmasks(self),
		collision_flag_manager.print_bitmasks($MeleeZoneEngage),
		collision_flag_manager.print_bitmasks($MeleeZoneDisengage),
		],
		true) # crash the game so there isn't too much output

func reset_movement_target():
	movement_target = position

func reset_tracking():
	chasing_enemy_unit = null
	reset_movement_target()

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

# Getters and checkers
func get_unit_name():
	return unit_name

func get_unit_group_tag():
	return unit_name

func get_icon_scale():
	return $IconSprite.scale

func get_icon_texture():
	return $IconSprite.texture

func get_body_shape():
	return $UnitBodyCollision.shape

func check_is_enemy_attackable(other_unit):
	var player_tag = game_world.get_player_group_tag(player_id, 'units')
	#var enemy_group_tags = game_world.get_other_players_group_tags(current_player_id, 'units')
	return not other_unit.is_in_group(player_tag)

func is_under_attack():
	return not attacked_by_enemies.empty()

func is_attacking():
	return not attacking_enemies.empty()


# Game loop functions
func _process(delta):
	update_combat(delta)

func _physics_process(delta):
	update_movement(delta)

# Movement functions
func update_movement(_delta):
	# Update this unit's movement and position.
	if not is_attacking():
		# This unit is not actively attacking anything. Carry on with moving

		if chasing_enemy_unit:
			# Chasing an enemy unit, update the target position every physics step
			set_movement_target(chasing_enemy_unit.global_position, group_speed)

		var gap = movement_target - position
		var speed = min(4*gap.length(), min(group_speed, unit_speed))
		#var speed = min(group_speed, unit_speed)

		if is_under_attack():
			# The unit is stuck in combat and can't move quickly
			speed = min(speed, fighting_speed)
		elif is_retreating and not is_under_attack() and gap.length_squared() < 5:
			# Was retreating, escaped, and reached retreat destination
			# End the retreat
			is_retreating = false


		velocity = gap.normalized() * speed
		var _velocity = move_and_slide(velocity)

func chase_enemy(other_unit, slowest_speed=INF, user_override_attack=false):
	dbg_print('combat_engagement', ["Checking if ", self, " can attack ", other_unit])
	if check_is_enemy_attackable(other_unit):
		dbg_print('combat_engagement', ["  ", self, " is chasing enemy ", other_unit])
		set_movement_target(
			other_unit.global_position, slowest_speed, user_override_attack
			)
		chasing_enemy_unit = other_unit

		if not $MeleeZoneEngage.monitoring:
			# Engagement zone not active yet, activate it then wait a frame
			engagement_zone_activate(preferred_attack_type)
			yield(get_tree(), "idle_frame")

		var overlapping = $MeleeZoneEngage.get_overlapping_bodies()
		if overlapping:
			dbg_print('combat_engagement',
				["!!! ", self, " is already overlapping ", overlapping])
			for body in overlapping:
				#_on_MeleeZoneEngage_body_entered(body)
				call_deferred("_on_MeleeZoneEngage_body_entered", body)
		else:
			dbg_print('combat_engagement',
				["!!! ", self, " is not overlapping others."])
	else:
		dbg_print('combat_engagement', ["  ", self, " cannot chase ", other_unit])

func set_movement_target(new_target, slowest_speed=INF, user_override_attack=false):
	if is_attacking() and user_override_attack:
		# Currently attacking, but commanded to retreat
		dbg_print('combat_engagement', ["Retreat! ", self])
		is_retreating = true
		for enemy in attacking_enemies:
			stop_attacking_unit(enemy, attacking_enemies[enemy])
	#elif not is_attacking() and is_under_attack() and user_override_attack:
	elif is_under_attack() and user_override_attack:
		# Currently being attacked by others, but still retreating
		dbg_print('combat_engagement', ["Retreat more! ", self])
		is_retreating = true
	else:
		if user_override_attack:
			# Normal movement command
			dbg_print('combat_engagement', ["Normal movement command for ", self])
		is_retreating = false
	movement_target = new_target
	group_speed = slowest_speed

# Combat loop functions (called frequently)
func update_combat(delta):
	if is_attacking():
		# Attacking stuff. Deal damage.
		for enemy in attacking_enemies:
			var attack_type = attacking_enemies[enemy]
			var damage_rate = damage_lookup[attack_type]
			enemy.receive_damage(damage_rate * delta)

			# Could start a time and deal larger damage amounts on timeout


# Combat receiving functions
func receive_damage(damage_amount):
	$HealthBarPosition/HealthBar.value -= damage_amount
	$HealthBarPosition.show()

func entered_attack_zone_of(enemy_unit, attack_type):
	# remember who is attacking this unit
	attacked_by_enemies[enemy_unit] = attack_type
	dbg_print('combat_engagement', [self, ' has been attacked by ', enemy_unit])

	if not is_attacking() and not is_retreating:
		# This unit was not expecting an attack, reciprocate the attack
		dbg_print('combat_engagement',
			['  ', self, ' is counter-attacking ', enemy_unit])
		chase_enemy(enemy_unit)
	else:
		# This unit was already attacking other units or is retreating. Ignore the new attacker
		if is_attacking():
			dbg_print('combat_engagement',
				[self, ' is ignoring new attacker ', enemy_unit,
				" because it's already attacking other units"]
				)
		if is_retreating:
			dbg_print('combat_engagement',
				[self, ' is ignoring new attacker ', enemy_unit,
				" because it is retreating"]
				)

func escaped_attack_zone_of(enemy_unit, attack_type):
	if enemy_unit in attacked_by_enemies:
		if attacked_by_enemies[enemy_unit] == attack_type:
			attacked_by_enemies.erase(enemy_unit)

# Combat emitting functions
func start_attacking_unit(enemy_unit, attack_type):
	dbg_print('combat_engagement',
		["Starting ", attack_type, " attack by ", self, " towards ", enemy_unit])
	# Rember who this unit is attacking and how
	attacking_enemies[enemy_unit] = attack_type

	# Let the enemy unit know as well
	enemy_unit.entered_attack_zone_of(self, attack_type)

	engagement_zone_deactivate(attack_type)
	disengagement_zone_activate(attack_type)

func stop_attacking_unit(enemy_unit, attack_type):
	dbg_print('combat_engagement',
		["Stopping ", attack_type, " attack by ", self, " towards ", enemy_unit])
	if attacking_enemies[enemy_unit] == attack_type:
		attacking_enemies.erase(enemy_unit)
		enemy_unit.escaped_attack_zone_of(self, 'melee')

		if not is_attacking():
			# Not actively attacking any enemies. Disable the disengagement zone
			disengagement_zone_deactivate(attack_type)

			if is_retreating:
				# The player is giving direct orders to stop attacking
				# Do not automatically target another unit.
				dbg_print('combat_engagement', '  Stopping attack because of retreat')
			elif not is_under_attack():
				# Not being attacked by anyone, follow the same enemy!
				dbg_print('combat_engagement', '  Following enemy')
				chase_enemy(enemy_unit)
			else:
				# Being attacked by other units, automatically switch to the closest one.
				dbg_print('combat_engagement', '  Switching to another attacker')
				var closest = null
				for enemy in attacked_by_enemies:
					if closest == null:
						closest = enemy
					else:
						var c_diff = closest.global_position - global_position
						var e_diff = enemy.global_position - global_position
						if e_diff.length_squared() < c_diff.length_squared():
							closest = enemy # Another enemy is closer
				chase_enemy(closest)


func _on_MeleeZoneEngage_body_entered(body:Node):
	dbg_print('combat_engagement',
		["Body ", body, " entered engagement zone of ", self])
	if body == chasing_enemy_unit:
		dbg_print('combat_engagement', ["  Body entered is the chasing target"])
		# This unit has caught the enemy unit, attack them with a melee attack
		start_attacking_unit(chasing_enemy_unit, 'melee')
	else:
		dbg_print('combat_engagement', ["  But body is not the chasing target. Ignoring it."])

func _on_MeleeZoneDisengage_body_exited(body:Node):
	dbg_print('combat_engagement',
		["Body ", body, " exited disengagement zone of ", self])
	if body in attacking_enemies:
		dbg_print('combat_engagement', ["  Body was being attacked"])
		# The enemy unit has escaped, stop attacking
		stop_attacking_unit(body, 'melee')

func engagement_zone_activate(_attack_type):
	dbg_print('combat_engagement', ["Activating engagement zone of ", self])
	$MeleeZoneEngage.set_deferred("monitoring", true)
	#$MeleeZoneEngage/MeleeZoneCollision.shape.set_deferred("disabled", false)

func engagement_zone_deactivate(_attack_type):
	dbg_print('combat_engagement', ["Deactivating engagement zone of ", self])
	$MeleeZoneEngage.set_deferred("monitoring", false)
	#$MeleeZoneEngage/MeleeZoneCollision.shape.set_deferred("disabled", true)

func disengagement_zone_activate(_attack_type):
	dbg_print('combat_engagement', ["Activating disengagement zone of ", self])
	$MeleeZoneDisengage.set_deferred("monitoring", true)
	#$MeleeZoneDisengage/MeleeZoneCollision.shape.set_deferred("disabled", false)

func disengagement_zone_deactivate(_attack_type):
	dbg_print('combat_engagement', ["Deactivating disengagement zone of ", self])
	$MeleeZoneDisengage.set_deferred("monitoring", false)
	#$MeleeZoneDisengage/MeleeZoneCollision.shape.set_deferred("disabled", true)

