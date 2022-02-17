extends Node2D

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

func guide_host(slowest_speed=INF):
	if host_unit:
		host_unit.set_movement_target(global_position, slowest_speed)

func get_host_speed():
	return host_speed
