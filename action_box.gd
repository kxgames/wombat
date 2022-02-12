extends Node2D

export(PackedScene) var ghost_scene

var is_actuating = false
var mouse_target_start = Vector2()
var mouse_target_end = Vector2()
var centroid = Vector2()
var selected_units = []
var ghost_list = []

func _ready():
	pass # Replace with function body.

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		is_actuating = false
		clear_ghost_list()

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
	mouse_target_start = get_global_mouse_position()
	mouse_target_end = get_global_mouse_position()
	position = mouse_target_start
	rotation = 0

	# Calculate centroid
	centroid = Vector2()
	for unit in selected_units:
		centroid += unit.position
	centroid /= selected_units.size()

	# Create unit ghosts with keeping relative positioning
	clear_ghost_list()
	for unit in selected_units:
		var ghost = ghost_scene.instance()
		ghost.embody(unit)
		#ghost.group_position = ghost.position - centroid
		ghost.position = unit.position - centroid
		add_child(ghost)
		#ghost_dict[ghost] = ghost.position - centroid
		ghost_list.append(ghost)

func end_new_action(_event):
	is_actuating = false
	clear_ghost_list()

func drag_new_action(_event):
	# Rotate ghosts to face mouse direction while keeping relative positioning.
	mouse_target_end = get_global_mouse_position()
	var direction = mouse_target_end - mouse_target_start
	# Rotate the formation without rotating the icons
	rotation = direction.angle()
	for ghost in ghost_list:
		ghost.rotation = -rotation

func clear_ghost_list():
	for ghost in ghost_list:
		ghost.queue_free()
	ghost_list = []

