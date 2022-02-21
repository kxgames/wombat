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

func guide_host(slowest_speed=INF, chase_unit=null):
	if host_unit:
		if chase_unit:
			host_unit.chase_enemy(chase_unit, slowest_speed, true)
		else:
			host_unit.reset_tracking()
			host_unit.set_movement_target(global_position, slowest_speed, true)
	else:
		emit_signal("delete_ghost", self)

func get_host_speed():
	return host_speed
