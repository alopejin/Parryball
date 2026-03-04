extends Node2D


var is_host = false
var player1_skin = Global.local_player1_skin[Global.index]
var player2_skin = Global.local_player2_skin[Global.index]

var noray_copy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Music.play()
	$Background.texture = preload("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	
	await NetworkManager.noray_connected
	
	if !NetworkManager.noray_copied:
		NetworkManager.noray_copy = Noray.oid
		NetworkManager.noray_copied = true
	
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy

func alternate_main_menu():
	$Main_menu.visible = !$Main_menu.visible

func alternate_play_menu():
	$Play_menu.visible = !$Play_menu.visible

func alternate_jam_menu():
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible

func alternate_jam_lan_menu():
	$LAN_menu_jam.visible = !$LAN_menu_jam.visible

func alternate_scored_menu():
	$Mode_menu_scored.visible = !$Mode_menu_scored.visible

func _on_play_button_pressed() -> void:
	$Click_sound.play()
	alternate_main_menu()
	alternate_play_menu()

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await get_tree().create_timer(0.2)
	get_tree().quit()

func _on_play_back_button_pressed() -> void:
	$Click_sound.play()
	alternate_main_menu()
	alternate_play_menu()

func _on_jam_button_pressed() -> void:
	$Click_sound.play()
	alternate_play_menu()
	alternate_jam_menu()
	$Label_gamemode.text = "   Jam:"

func _on_local_jam_button_pressed() -> void:
	$Click_sound.play()
	$Label_gamemode.visible = false
	$Background.texture = load("res://assets/sprites/fondo1-ajustado.png")
	$Local_menu_jam.visible = !$Local_menu_jam.visible
	$Local_customizer.show()
	alternate_jam_menu()

func _on_local_jam_back_button_pressed() -> void:
	$Local_menu_jam.visible = !$Local_menu_jam.visible
	$Local_customizer.hide()
	$Background.texture = load("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	$Label_gamemode.visible = true
	alternate_jam_menu()

func _on_start_local_jam_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/local_jam.tscn")

func _on_lan_jam_button_pressed() -> void:
	$Click_sound.play()
	alternate_jam_lan_menu()
	alternate_jam_menu()
	$Online_customizer.show()

func _on_lan_jam_menu_back_button_pressed() -> void:
	$Click_sound.play()
	alternate_jam_lan_menu()
	alternate_jam_menu()
	$Online_customizer.hide()

func _on_lan_jam_host_button_pressed() -> void:
	is_host = true
	$Click_sound.play()
	LANNetworkManager.receive_player_info($LAN_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_jam/Ip_adress.text == "":
		$LAN_menu_jam/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_jam/Port.text == "":
		$LAN_menu_jam/Port.text = "22022"
	
	LANNetworkManager.is_hosting = true
	LANNetworkManager.host_game($LAN_menu_jam/Ip_adress.text, $LAN_menu_jam/Port.text)


func _on_lan_jam_join_button_pressed() -> void:
	$Click_sound.play()
	LANNetworkManager.receive_player_info($LAN_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_jam/Ip_adress.text == "":
		$LAN_menu_jam/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_jam/Port.text == "":
		$LAN_menu_jam/Port.text = "22022"
	
	LANNetworkManager.join_game($LAN_menu_jam/Ip_adress.text, $LAN_menu_jam/Port.text)

func _on_start_jam_game_button_pressed() -> void:
	if !is_host: # or multiplayer.get_peers().size() != 2
		return
	LANNetworkManager.start_game.rpc()
	self.hide.rpc()
	$Music.stop.rpc()

func _on_online_jam_button_pressed() -> void:
	$Click_sound.play()
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible
	$Online_menu_jam.visible = !$Online_menu_jam.visible
	$Online_customizer.show()

func _on_online_jam_host_button_pressed():
	$Click_sound.play()
	NetworkManager.receive_player_info($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	NetworkManager.host()
	#await  multiplayer.connected_to_server
	#NetworkManager.send_player_info.rpc_id(1, $Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())
	#NetworkManager.send_player_info.rpc($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined")
			#await NetworkManager.receive_player_info($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
			#await NetworkManager.rpc_id(1, player_name, player_skin, multiplayer.get_unique_id())
			#NetworkManager.send_player_info.rpc($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())
	)

func _on_online_jam_join_button_pressed():
	$Click_sound.play()
	NetworkManager.join($Online_menu_jam/OID_input.text)
	await multiplayer.connected_to_server
	
	NetworkManager.send_player_info.rpc($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())

func _on_online_jam_start_button_pressed():
	#if !is_host: # or multiplayer.get_peers().size() != 2
	#	return
	NetworkManager.start_game.rpc()
	print("Start")

func _on_online_jam_menu_back_button_pressed():
	$Click_sound.play()
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible
	$Online_menu_jam.visible = !$Online_menu_jam.visible
	$Online_customizer.hide()

func _on_jam_menu_back_button_pressed() -> void:
	$Click_sound.play()
	alternate_jam_menu()
	alternate_play_menu()
	$Label_gamemode.text = ""

func _on_scored_button_pressed() -> void:
	$Click_sound.play()
	alternate_play_menu()
	alternate_scored_menu()
	$Label_gamemode.text = " Scored:"

func _on_local_scored_button_pressed() -> void:
	$Click_sound.play()
	$Label_gamemode.visible = false
	$Background.texture = load("res://assets/sprites/fondo1-ajustado.png")
	$Local_menu_scored.visible = !$Local_menu_scored.visible
	$Local_customizer.show()
	alternate_scored_menu()

func _on_local_scored_menu_back_button_pressed() -> void:
	$Click_sound.play()
	$Label_gamemode.visible = true
	$Background.texture = load("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	$Local_menu_scored.visible = !$Local_menu_scored.visible
	$Local_customizer.hide()
	alternate_scored_menu()

func _on_start_local_scored_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/local_multiplayer.tscn")

func _on_online_scored_button_pressed() -> void:
	$Click_sound.play()

func _on_scored_menu_back_button_pressed() -> void:
	$Click_sound.play()
	alternate_scored_menu()
	alternate_play_menu()
	$Label_gamemode.text = ""

func _on_online_menu_jam_copy_button_pressed():
	DisplayServer.clipboard_set(Noray.oid)

func _on_online_menu_jam_delete_button_pressed() -> void:
	$Online_menu_jam/OID_input.text = ""

func _on_online_menu_jam_recover_button_pressed() -> void:
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
