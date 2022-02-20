extends Node2D

onready var game_world = get_node("/root/GameWorld")

export(PackedScene) var ghost_scene

var current_player_id = 1
var is_actuating = false
var mouse_target_start = Vector2()
var mouse_target_end = Vector2()
var centroid = Vector2()
var init_drag_angle = null
var selected_units = []
var ghost_list = []
var mouse_hovering_dict = {} # {unit : unit}
var attack_target = null

func _ready():
	pass

func switch_player(player_id):
	current_player_id = player_id
	selected_units = []
	reset()

func reset():
	is_actuating = false
	attack_target = null
	clear_ghost_list()

func update_selection(new_selection):
	reset()
	selected_units = new_selection

func hovering_dict_add(unit):
	assert(not unit in mouse_hovering_dict)
	mouse_hovering_dict[unit] = unit

func hovering_dict_erase(unit):
	assert(unit in mouse_hovering_dict)
	mouse_hovering_dict.erase(unit)

func _unhandled_input(event):
	# Note: Use _unhandled_input rather than _input to allow (future) GUIS to grab input first
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if selected_units.size() > 0:
					start_new_action(event)
			else:
				end_new_action(event)

	elif event is InputEventMouseMotion:
		if is_actuating:
			drag_new_action(event)

func start_new_action(_event):
	is_actuating = true
	init_drag_angle = null
	mouse_target_start = get_global_mouse_position()
	mouse_target_end = get_global_mouse_position()
	position = mouse_target_start
	rotation = 0

	# Calculate centroid
	centroid = Vector2()
	for unit in selected_units:
		centroid += unit.position
	centroid /= selected_units.size()

	# Check if the mouse is right clicking a unit
	var is_click_over_enemy = false
	var hovered_unit = null
	if not mouse_hovering_dict.empty():
		assert(mouse_hovering_dict.size() == 1)
		hovered_unit = mouse_hovering_dict.values()[0]
		is_click_over_enemy = check_is_attackable(hovered_unit)

	# Create ghosts for each selected unit
	clear_ghost_list()
	for unit in selected_units:
		var ghost = ghost_scene.instance()
		add_child(ghost)
		ghost.embody(unit)
		ghost_list.append(ghost)
		ghost.connect("delete_ghost", self, "_on_delete_ghost")

		if is_click_over_enemy:
			# Targetting enemy unit for attack! (wait for release to execute)
			# Save the target because the dict will likely change soon
			attack_target = hovered_unit
			position = attack_target.global_position
			ghost.position = Vector2() # All ghosts are positioned on the target
			ghost.hide_sprite()
		else:
			# Not right clicking on an enemy. Show formation.
			# Keep relative positioning from centroid
			attack_target = null
			ghost.position = unit.position - centroid

func check_is_attackable(unknown_unit):
	if unknown_unit == null:
		return(false)
	var player_tag = game_world.get_player_group_tag(current_player_id, 'units')
	#var enemy_group_tags = game_world.get_other_players_group_tags(current_player_id, 'units')
	return not unknown_unit.is_in_group(player_tag)

func drag_new_action(_event):
	if attack_target:
		# Ignore dragging if targetting a unit
		update()
		return

	# Rotate ghosts to face mouse direction while keeping relative positioning.
	mouse_target_end = get_global_mouse_position()
	var direction = mouse_target_end - mouse_target_start

	# Use the initial drag direction angle (after moving 10 units away) as the
	# zero-rotation direction. Makes moving units around  a little more intuitive.
	if direction.length() < 10:
		return
	if not init_drag_angle:
		init_drag_angle = direction.angle()

	# Rotate the group without rotating the icons
	rotation = direction.angle() - init_drag_angle
	for ghost in ghost_list:
		ghost.rotation = -rotation
	update()

func end_new_action(_event):
	is_actuating = false

	# Find the slowest unit speed in the group
	var slowest_speed = INF
	for ghost in ghost_list:
		slowest_speed = min(slowest_speed, ghost.get_host_speed())

	# Move all the units with the slowest unit
	for ghost in ghost_list:
		ghost.guide_host(slowest_speed, attack_target)
	clear_ghost_list()

func _on_delete_ghost(dead_ghost):
	# One ghost is deleted
	var new_list = []
	for ghost in ghost_list:
		if ghost == dead_ghost:
			ghost.queue_free()
		else:
			new_list.append(ghost)
	ghost_list = new_list
	update()

func clear_ghost_list():
	# Delete all ghosts
	for ghost in ghost_list:
		ghost.queue_free()
	ghost_list = []
	update()

func _draw():
	if is_actuating:
		# Draw a line showing the mouse drag
		#draw_line(
		#	Vector2(), 
		#	(mouse_target_end - mouse_target_start).rotated(-rotation),
		#	Color(0.5, 0.5, 0.5),
		#	true
		#	)

		# Draw faint lines to show where units are going to go
		for ghost in ghost_list:
			draw_line(
				(ghost.host_unit.global_position - position).rotated(-rotation),
				#offset.rotated(-rotation),
				(ghost.global_position - position).rotated(-rotation),
				Color(0.25, 0.25, 0.25),
				true
				)
