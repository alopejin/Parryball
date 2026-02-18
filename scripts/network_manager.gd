extends Node


const IP_ADRESS = "192.168.56.1"
const PORT = 22022

var peer :ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)

func start_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = peer
	print("Host connected")

func start_client():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(id: int = 1):
	var player_scene = load("res://scenes/player-online.tscn")
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player, true)
	if id == 1:
		player.global_position = Vector2(562, 903)
	else:
		player.global_position = Vector2(1373, 903)
	
	if multiplayer.get_peers().size() == 1:
		player.get_parent().player1 = player
		player.global_position = Vector2(562, 903)
	else:
		player.get_parent().player2 = player
		player.global_position = Vector2(1373, 903)
		player.get_parent().start_game()
	
	print("joder")
