extends Node


signal noray_connected

const NORAY_ADDRESS = "tomfol.io"
const PORT = 8890

#var peer :ENetMultiplayerPeer
var players = {}
var player_name : String
var player_skin : String
var player1_serves : bool

var is_host = false
var external_oid = ""

var noray_copied = false
var noray_copy = ""

func _ready() -> void:
	
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	Noray.connect_to_host(NORAY_ADDRESS, PORT)

func on_noray_connected():
	print("Connected to Noray server")
	
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	
	noray_connected.emit()

func host():
	print("Hosting")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	is_host = true
	send_player_info(player_name, player_skin, multiplayer.get_unique_id())

func join(oid):
	Noray.connect_nat(oid)
	external_oid = oid

func handle_nat_connection(address, port):
	var err = await connect_to_server(address, port)
	
	if err != OK and !is_host:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	
	return err

func handle_relay_connection(address, port):
	return await connect_to_server(address, port)

func connect_to_server(address, port):
	var err = OK
	
	if !is_host:
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				return err
		else:
			print("Handshake success")
		
		var peer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
		if err != OK:
			return err
		
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
	
	if multiplayer.is_server():
		for i in players:
			send_player_info.rpc(players[i].name, players[i].skin, i)

@rpc("any_peer", "call_local")
func start_game():
	get_tree().change_scene_to_file("res://scenes/online_jam.tscn")

func receive_player_info(n : String, s : String):
	player_name = n
	player_skin = s
