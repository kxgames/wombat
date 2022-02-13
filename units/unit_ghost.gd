extends Node2D

var host_unit = null

func embody(unit):
	# Copy information from the unit
	host_unit = unit
	#position = unit.position
	#rotation = unit.rotation
	$GhostSprite.texture = unit.get_icon_texture()
	$GhostSprite.scale = unit.get_icon_scale()

func guide_host():
	if host_unit:
		host_unit.set_movement_target(global_position)
