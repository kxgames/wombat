extends Node2D

signal delete_ghost(ghost)

var host_unit = null
var host_speed = INF

func embody(unit):
	# Copy information from the unit
	host_unit = unit
	#position = unit.position
	#rotation = unit.rotation
	host_speed = unit.unit_speed
	$GhostSprite.texture = unit.get_icon_texture()
	$GhostSprite.scale = unit.get_icon_scale()

func hide_sprite():
	$GhostSprite.hide()
	$WhiteBackground.hide()

func guide_host(slowest_speed=INF, attack_unit=null):
	print("Guide host: ", host_unit, ", ", slowest_speed, ", ", attack_unit)
	if host_unit:
		if attack_unit:
			host_unit.attack_enemy(attack_unit, slowest_speed)
		else:
			host_unit.reset_tracking()
			host_unit.set_movement_target(global_position, slowest_speed)
	else:
		emit_signal("delete_ghost", self)

func get_host_speed():
	return host_speed
