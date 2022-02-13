extends KinematicBody2D

var is_selected = false
var movement_target : Vector2

export var max_speed = 100
var velocity :Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	movement_target = position
	$SelectedSprite.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(_delta):
	var gap = movement_target - position
	velocity = gap.normalized() * min(max_speed, gap.length())
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

func set_movement_target(new_target):
	movement_target = new_target
