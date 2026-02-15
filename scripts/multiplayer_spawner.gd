extends MultiplayerSpawner


@export var network_player: PackedScene

func _ready() -> void:
	#multiplayer.peer_connected.connect(spawn_player)
	pass

func spawn_player(id: int = 1):
	if multiplayer.is_server():
		var player = network_player.instantiate()
		player.name = str(id)
		if player.is_multiplayer_authority():
			player.global_position = Vector2(562, 903)
		else:
			player.global_position = Vector2(1373, 903)
		
		get_node(spawn_path).call_deferred("add_child", player)
		
		print("Player " + str(id) + " connected!")
		print(str(player.is_multiplayer_authority()))
