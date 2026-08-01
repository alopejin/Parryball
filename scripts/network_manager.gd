extends Node


signal noray_connected
signal client_ready
signal join_available
signal votes_updated(v)
#signal player_disconnected(id)
signal lobby_updated(id)

const PORT = 8890

var noray_adress = "tomfol.io"
var players = {}
var player_name : String
var player_skin : String
var player1_serves : bool

var connecting : bool = false
var connected_noray : bool = false

var is_host = false
var external_oid = ""

var noray_copied = false
var noray_copy = ""

var votes = 0
var has_voted = false

var notifications = null
var join_attempt = 0

var client_id = 0

func _ready() -> void:
	
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	multiplayer.peer_connected.connect(client_copy)
	multiplayer.server_disconnected.connect(peer_disconnected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(_on_client_connected)
	
	Noray.connect_to_host(noray_adress, PORT)

func on_noray_connected():
	print("Connected to Noray server")
	
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	connected_noray = true
	
	noray_connected.emit()

func host():
	print("Hosting")
	reset_connections()
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	is_host = true
	send_player_info(player_name, player_skin, multiplayer.get_unique_id())

func join(oid):
	reset_connections()
	connecting = true
	var actual_attempt = join_attempt
	
	notifications.connection_attempt_N()
	Noray.connect_nat(oid)
	external_oid = oid
	
	await get_tree().create_timer(20.0).timeout
	
	if connecting and join_attempt == actual_attempt:
		connecting = false
		notifications.connection_failed_N()

func handle_nat_connection(address, port):
	var actual_attempt = join_attempt
	var err = await connect_to_server(address, port, false, actual_attempt)
	
	if err != OK and !is_host and actual_attempt == join_attempt:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	return err

func handle_relay_connection(address, port):
	return await connect_to_server(address, port, true, join_attempt)

func connect_to_server(address, port, notify_failure := false, attempt_id := 0):
	var err = OK
	
	if !is_host:
		if attempt_id != join_attempt or multiplayer.multiplayer_peer != null:
			print("Obslote attempt")
			return ERR_SKIP
		
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)

		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				
				if notify_failure:
					connecting = false
					join_attempt += 1
					notifications.connection_failed_N()
					join_available.emit()
				
				return err
		else:
			print("Handshake success")
		
		var peer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		print("create_client returns: " + str(err))
		
		if attempt_id != join_attempt or multiplayer.multiplayer_peer != null:
			print("Obsolete attempt")
			return ERR_SKIP
		
		if err != OK:
			if notify_failure:
				connecting = false
				join_attempt += 1
				notifications.connection_failed_N()
				join_available.emit()
			return err
		
		connecting = false
		join_attempt += 1
		notifications.connection_success_N()
		join_available.emit()
		
		multiplayer.multiplayer_peer = peer
		
		return OK
	
	else:
		
		err = await PacketHandshake.over_enet(multiplayer.multiplayer_peer.host, address, port)
	
	return err

@rpc("any_peer")
func send_player_info(name, skin, id):
	if !players.has(id):
		players[id] = {
			"name" : name,
			"skin" : skin,
			"id" : id
		}
	
	lobby_updated.emit(id)
	
	if multiplayer.is_server():
		for i in players:
			send_player_info.rpc(players[i].name, players[i].skin, i)
		
		if players.size() == 2:
			notify_all_ready.rpc()

@rpc("authority", "call_local")
func start_online_jam():
	votes = 0
	has_voted = false
	get_tree().change_scene_to_file("res://scenes/online_jam.tscn")

@rpc("authority", "call_local")
func start_online_scored():
	votes = 0
	has_voted = false
	get_tree().change_scene_to_file("res://scenes/online_scored.tscn")

func receive_player_info(n : String, s : String):
	player_name = n
	player_skin = s

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
	is_host = false
	connecting = false
	external_oid = ""
	join_attempt += 1 

func reset_noray():
	reset_connections()
	connected_noray = false
	noray_copied = false
	noray_copy = ""
	client_id = ""
	Noray.connect_to_host(noray_adress, PORT)
	#await noray_connected
	await get_tree().create_timer(1.25).timeout
	
	if connected_noray:
		noray_copy = Noray.oid
		noray_copied = true
		
		lobby_updated.emit(-1)
		notifications.noray_restarted_N()
	else:
		notifications.server_down_N()

func reset_connections():
	reset_enet()
	reset_network()

func peer_disconnected(id = 1):
	print("Peer " + str(id) + " disconnected")
	#player_disconnected.emit(id)

func _on_client_connected():
	print("Connected to server")
	send_player_info.rpc_id(1, player_name, player_skin, multiplayer.get_unique_id())

func client_copy(id):
	print("Peer " + str(id) + " connected")
	client_id = id
