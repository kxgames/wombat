extends Node2D

export var group_position:Vector2 = Vector2()

func embody(unit):
	# Copy information from the unit
	#position = unit.position
	#rotation = unit.rotation
	$GhostSprite.texture = unit.get_icon_texture()
	$GhostSprite.scale = unit.get_icon_scale()
