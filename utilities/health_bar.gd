extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	hide()

func is_depleted():
	return $HealthBarControl.value <= $HealthBarControl.min_value

func is_full():
	return $HealthBarControl.value >= $HealthBarControl.max_value

func change_health(health_delta):
	$HealthBarControl.value += health_delta

	if is_full():
		# Health bar is full, hide it
		hide()
	else:
		# Health bar is partial, show it
		show()
