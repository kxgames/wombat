extends Area2D

signal selection_finished()

var is_selecting = false
var is_ctrl_selecting = false
var is_cancelling = false
var start_pos = Vector2()
var end_pos = Vector2()

var selection_dict = {} # {unit : is_selected}

func get_current_selection():
	var current_selection = []
	for unit in selection_dict:
		if selection_dict[unit]:
			current_selection.append(unit)
	return current_selection

# Called when the node enters the scene tree for the first time.
func _ready():
	$SelectionBoxCollision.disabled = true

func _process(_delta):
	if Input.is_action_pressed("ui_cancel"):
		is_selecting = false
		clear_existing_selection()

func _unhandled_input(event):
	# Note: Use _unhandled_input rather than _input to allow (future) GUIS to grab input first
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if not (event.shift or event.control):
					# Clear existing selection if not clicking with a modifier
					clear_existing_selection()
				start_new_selection(event)
				is_ctrl_selecting = event.control
			else:
				end_new_selection(event)

	elif event is InputEventMouseMotion:
		if is_selecting:
			drag_new_selection(event)
		is_ctrl_selecting = event.control

func start_new_selection(_event):
	# Starting a new selection action
	is_selecting = true

	# Set positions and collision box
	#position = event.position # sets the Area2D's position
	position = get_global_mouse_position()
	start_pos = position
	end_pos = position
	update_collision_box()
	$SelectionBoxCollision.set_deferred("disabled", false)

func drag_new_selection(_event):
	# Continuing a selection action
	end_pos = get_global_mouse_position()
	update_collision_box()
	update()
	#call_deferred("check_for_selections")

func end_new_selection(_event):
	# Ending a selection action
	is_selecting = false
	$SelectionBoxCollision.set_deferred("disabled", true)
	update()
	#if not (event.shift or event.control):
	emit_signal("selection_finished")

func set_selection(unit, new_status):
	assert(unit.has_method("update_unit_selection"))
	if not unit in selection_dict or selection_dict[unit] != new_status:
		# New unit or existing unit's status is changing, actually do stuff
		selection_dict[unit] = new_status
		unit.update_unit_selection(new_status)

func clear_existing_selection():
	# Clear out existing selections
	for unit in selection_dict:
		set_selection(unit, false)

func _on_SelectionBox_body_entered(body):
	if is_selecting and body.has_method("update_unit_selection"):
		# The body is a selectable unit, select it (if not ctrl clicking)
		set_selection(body, not is_ctrl_selecting)

func _on_SelectionBox_body_exited(body):
	if is_selecting and body.has_method("update_unit_selection"):
		# The body is a selectable unit, unselect it (if not ctrl clicking)
		set_selection(body, is_ctrl_selecting)

func update_collision_box():
	""" Calculate the positions of the selection box area and collision shape. """

	# Set the collision shape's positon to the center of the selection region
	var box_center = (end_pos - start_pos) / 2.0
	$SelectionBoxCollision.position = box_center

	# Set the collision rect extents to half the width/height (it's used like 
	# radius). Values are restricted to greater than 1 (so very small, thin, 
	# or no-drag selection boxes have a collision shape still)
	var extents = box_center.abs()
	var min_extent = 1.0
	extents.x = max(extents.x, min_extent)
	extents.y = max(extents.y, min_extent)
	$SelectionBoxCollision.shape.set_deferred("extents", extents)

func _draw():
	if is_selecting: # and end_pos != start_pos:
		# Draw a simple box showing the mouse drag area.
		draw_rect(
			Rect2(Vector2(), end_pos - start_pos),
			Color(0.5, 0.5, 0.5),
			false
			)
