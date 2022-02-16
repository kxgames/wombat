extends Node2D

export(PackedScene) var ghost_scene

var is_actuating = false
var mouse_target_start = Vector2()
var mouse_target_end = Vector2()
var centroid = Vector2()
var init_drag_angle = null
var selected_units = []
var ghost_list = []

func _ready():
	pass # Replace with function body.

func update_selection(new_selection):
	selected_units = new_selection

func _unhandled_input(event):
	# Note: Use _unhandled_input rather than _input to allow (future) GUIS to grab input first
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed and selected_units.size() > 0:
				start_new_action(event)
			else:
				end_new_action(event)

	elif event is InputEventMouseMotion:
		if is_actuating:
			drag_new_action(event)

func start_new_action(_event):
	is_actuating = true
	init_drag_angle = null

	# Calculate centroid
	centroid = Vector2()
	for unit in selected_units:
		centroid += unit.position
	centroid /= selected_units.size()

	mouse_target_start = get_global_mouse_position()
	mouse_target_end = get_global_mouse_position()
	position = mouse_target_start
	rotation = 0

	# Create unit ghosts with keeping relative positioning
	clear_ghost_list()
	for unit in selected_units:
		var ghost = ghost_scene.instance()
		ghost.embody(unit)
		ghost.position = unit.position - centroid
		add_child(ghost)
		ghost_list.append(ghost)

func end_new_action(_event):
	is_actuating = false
	for ghost in ghost_list:
		ghost.guide_host()
	clear_ghost_list()

func drag_new_action(_event):
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

func clear_ghost_list():
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
