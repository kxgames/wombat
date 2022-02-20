extends CanvasLayer

onready var game_world = get_node("/root/GameWorld")

signal switch_player(new_player_id)

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func add_new_player(player_id):
	$SelectPlayerButton.add_item("Player %d"%player_id)

func _on_SelectPlayerButton_item_selected(index):
	print("Switching players to Player ", index + 1)
	emit_signal("switch_player", index + 1)

