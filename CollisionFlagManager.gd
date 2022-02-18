extends Node

var layer_names_dict = {} # {'name' : id_number}
var layer_ids_dict = {} # {id_number : 'name'}
var units_layer_name_format = "Units_p%d"
var all_player_ids = [1]

func _ready():
	for i in range(1, 21):
		# Get the names of each layer
		# Based on https://godotengine.org/qa/108394/possible-collision-layer-mask-value-using-array-layer-names
		var layer_name_str = "layer_names/2d_physics/layer_" + str(i)
		var layer_name = ProjectSettings.get_setting(layer_name_str)

		# Only use named layers, ignore the others for now
		if layer_name:
			# Make sure layer wasn't added already
			assert(not layer_name in layer_names_dict)
			assert(not i in layer_ids_dict)

			# Add the layer to the dictionaries
			layer_names_dict[layer_name] = i
			layer_ids_dict[i] = layer_name

# Getters
func get_other_players_ids(player_id):
	var others = []
	for p_id in all_player_ids:
		if p_id != player_id:
			others.append(p_id)
	return others

func get_layer_names(player_ids):
	if typeof(player_ids) == TYPE_ARRAY:
		# Multiple player ids given
		# Call this function again on each id individually.
		var layer_names = []
		for p_id in player_ids:
			layer_names.append(get_layer_names(p_id))
		return layer_names
	else:
		# Single player id given
		return units_layer_name_format % player_ids

func get_player_layer(collision_object, player_ids):
	""" Get the layer flag for a single or multiple player(s) for a collision object. """
	return get_collision_layer(collision_object, get_layer_names(player_ids))

func get_player_mask(collision_object, player_ids):
	""" Get the mask flag for a single or multiple player(s) for a collision object. """
	return get_collision_mask(collision_object, get_layer_names(player_ids))

func get_collision_layer(collision_object, layer_names):
	""" Get the layer flag for a single or multiple named layer(s) for a collision object. """
	return manage_collision_flags('layer', collision_object, layer_names, null, false)

func get_collision_mask(collision_object, layer_names):
	""" Get the mask flag for a single or multiple named layer(s) for a collision object. """
	return manage_collision_flags('mask', collision_object, layer_names, null, false)

# Setters
func set_all_player_ids(new_list):
	all_player_ids = new_list

func set_player_layer(collision_object, player_ids, new_value):
	""" Set the layer flag for a single or multiple player(s) for a collision object. """
	set_collision_layer(collision_object, get_layer_names(player_ids), new_value)

func set_player_mask(collision_object, player_ids, new_value):
	""" Set the mask flag for a single or multiple player(s) for a collision object. """
	set_collision_mask(collision_object, get_layer_names(player_ids), new_value)

func set_collision_layer(collision_object, layer_names, new_value):
	""" Set the layer flag for a single or multiple named layer(s) for a collision object. """
	manage_collision_flags('layer', collision_object, layer_names, new_value)

func set_collision_mask(collision_object, layer_names, new_value):
	""" Set the mask flag for a single or multiple named layer(s) for a collision object. """
	manage_collision_flags('mask', collision_object, layer_names, new_value)

# Physics layers functions
func manage_collision_flags(
	layer_or_mask:String,
	collision_object:CollisionObject2D,
	layer_names,
	new_value=true,
	is_setter=true
	):
	"""
	Set or get the layer or mask flag for a single named or multiple named layer(s) 
	for a collision object.

	Parameters
	----------
	layer_or_mask : String
		Indicates whether this function is acting on a layer or a mask. Values 
		must be either 'layer' or 'mask'.
	collision_object : CollisionObject2D
		The physics object in question.
	layer_names : String or list of Strings
		The name or names of layers to act on. Can be a single name or a list 
		of names.
	new_value : bool=true
		The new value to assign to the given layer(s).
	is_setter :  bool=true
		Indicates if the function is setting the value of the layer(s) or 
		getting the values from the layer(s). If 'is_setter' is true, then 
		there are no return values. If 'is_setter' is false, then 
		'new_value' is ignored and the value or a list of values is returned, 
		matching the 'layer_names' argument.
	"""

	if typeof(layer_names) == TYPE_ARRAY:
		# Multiple layer names given
		# Call this function again for each individual layer
		if is_setter:
			for ln in layer_names:
				manage_collision_flags(layer_or_mask, collision_object, ln, new_value)
		else:
			var return_list = []
			for ln in layer_names:
				return_list.append(
					manage_collision_flags(
						layer_or_mask, collision_object, ln, new_value, false
						)
					)
			return return_list
	else:
		# Single layer name given
		check_layer_or_mask(layer_or_mask)
		check_layer_name(layer_names)
		var bit = layer_names_dict[layer_names] - 1
		if layer_or_mask == 'layer':
			if is_setter:
				collision_object.set_collision_layer_bit(bit, new_value)
			else:
				return collision_object.get_collision_layer_bit(bit)
		elif layer_or_mask == 'mask':
			if is_setter:
				collision_object.set_collision_mask_bit(bit, new_value)
			else:
				return collision_object.get_collision_mask_bit(bit)

func check_layer_name(layer_name):
	var available_str = "Available layer names: %s" % String(layer_names_dict.keys())
	var err_msg = "Layer name does not exist: %s\n%s" % [layer_name, available_str]
	assert(layer_name in layer_names_dict.keys(), err_msg)

func check_layer_or_mask(layer_or_mask):
	var err_msg = "Not a supported option: %s" % layer_or_mask
	assert(layer_or_mask in ['layer', 'mask'], err_msg)
