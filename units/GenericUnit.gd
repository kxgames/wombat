extends KinematicBody2D

var is_selected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$SelectedSprite.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
