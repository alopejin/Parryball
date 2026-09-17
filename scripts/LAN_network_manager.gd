extends Node


signal client_ready
signal join_available
signal votes_updated(v)
signal lobby_updated(id)

var ip_adress = "192.168.56.1"
var port = 22022

var peer :ENetMultiplayerPeer
var players = {}
var player_name : String
var player_skin : String
var player1_serves : bool

var votes = 0
var has_voted = false

var notifications = null
var join_attempt = 0

var client_id = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_connected.connect(client_copy)
	multiplayer.connected_to_server.connect(_on_client_connected)

func host_game(ip, p):
	ip_adress = ip
	port = p.to_int()
	start_server()

func join_game(ip, p):
	ip_adress = ip
	port = p.to_int()
	start_client()

func start_server():
	reset_connections()
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 2)
	multiplayer.multiplayer_peer = peer
	print("Host connected")
	send_player_info(player_name, player_skin, multiplayer.get_unique_id())

func start_client():
	reset_connections() 
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
	

@rpc("authority", "call_local")
func start_lan_jam():
	if is_inside_tree(): 
		get_tree().change_scene_to_file("res://scenes/LAN_jam.tscn")

@rpc("authority", "call_local")
func start_lan_scored():
	if is_inside_tree(): 
		get_tree().change_scene_to_file("res://scenes/LAN_scored.tscn")

@rpc("any_peer")
func send_player_info(name, skin, id):
	players[id] = {
		"name" : name,
		"skin" : skin,
		"id" : id
	}
	
	lobby_updated.emit(id)
	
	if multiplayer.is_server():
		print(str(players.size()))
		for i in players:
			send_player_info.rpc(players[i].name, players[i].skin, i)
		
		if players.size() == 2:
			notify_all_ready.rpc()

func quit_game(id = 1):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if is_inside_tree(): 
		get_tree().change_scene_to_file("res://scenes/main.tscn")

@rpc("any_peer")
func request_vote(value):
	if !multiplayer.is_server():
		return
	
	var aux = votes + value
	
	if aux < 0:
		aux = 0
	elif aux > 2:
		aux = 2
	
	votes = aux
	sync_votes.rpc(votes)

@rpc("authority", "call_local")
func sync_votes(v):
	votes = v
	votes_updated.emit(v)

@rpc("authority", "call_local")
func notify_all_ready():
	client_ready.emit()

func reset_enet():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func reset_network():
	players.clear()
	join_attempt += 1 

func reset_connections():
	reset_enet()
	reset_network()

func client_copy(id):
	print("Peer " + str(id) + " connected")
	client_id = id
