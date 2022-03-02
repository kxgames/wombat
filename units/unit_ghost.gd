extends Node2D
onready var game_world = get_node("/root/GameWorld")

signal delete_ghost(ghost)

var host_unit = null
var host_id = null
var host_speed = INF

func embody(unit):
	# Copy information from the unit
	host_unit = unit
	#position = unit.position
	#rotation = unit.rotation
	host_speed = unit.unit_speed
	host_id = unit.get_instance_id()
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

func _on_unit_deleted(deleted_unit_id):
	if host_id == deleted_unit_id:
		game_world.debug_print('unit_death',
			["Ghost host unit has died (id = ", deleted_unit_id, ")"])
		emit_signal("delete_ghost", self)

func get_host_speed():
	return host_speed
