extends Node


var ip_adress = "192.168.56.1"
var port = 22022

var peer :ENetMultiplayerPeer
var players = {}
var player_name : String
var player_skin : String
var player1_serves : bool

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(quit_game)

func host_game(ip, p):
	ip_adress = ip
	port = p.to_int()
	start_server()

func join_game(ip, p):
	ip_adress = ip
	port = p.to_int()
	start_client()

func start_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 2)
	multiplayer.multiplayer_peer = peer
	print("Host connected")
	send_player_info(player_name, player_skin, multiplayer.get_unique_id())

func start_client():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_adress, port)
	multiplayer.multiplayer_peer = peer

func receive_player_info(n : String, s : String):
	player_name = n
	player_skin = s

func _on_peer_connected(id: int = 1):
	print("Player connected: " + str(id))

func _on_client_connected():
	print("Connected to server")
	send_player_info.rpc_id(1, player_name, player_skin, multiplayer.get_unique_id())
	

@rpc("any_peer", "call_local")
func start_game():
	get_tree().change_scene_to_file("res://scenes/online_jam.tscn")

@rpc("any_peer")
func send_player_info(name, skin, id):
	if !players.has(id):
		players[id] = {
			"name" : name,
			"skin" : skin,
			"id" : id
		}
	
	if multiplayer.is_server():
		for i in players:
			send_player_info.rpc(players[i].name, players[i].skin, i)

func quit_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
