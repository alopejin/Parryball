extends Node2D


@onready var notifications = $Notifications
@onready var lobby_ui = $Lobby_UI

var is_host = false
var player1_skin = Global.local_player1_skin[Global.index]
var player2_skin = Global.local_player2_skin[Global.index]
var sound_on = true

var online_scored = false
var playing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.notifications = notifications

	NetworkManager.client_ready.connect(ready_to_start)
	NetworkManager.join_available.connect(enable_join_buttons)
	NetworkManager.lobby_updated.connect(update_lobby)
	
	multiplayer.peer_connected.connect(player_joined) 
	multiplayer.peer_disconnected.connect(player_disconnected)
	
	enable_join_buttons()
	disable_start_buttons()
	$Music.play()
	
	$Background.texture = preload("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	
	await NetworkManager.noray_connected
	
	if !NetworkManager.noray_copied:
		NetworkManager.noray_copy = Noray.oid
		NetworkManager.noray_copied = true
	
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
	$Online_menu_scored/OID_input.text = NetworkManager.noray_copy

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
	#$Main_menu/Play_button/AnimationPlayer.play("pressed")
	#await $Main_menu/Play_button/AnimationPlayer.animation_finished
	await button_press_animation($Main_menu/Play_button)
	alternate_main_menu()
	alternate_play_menu()

func _on_settings_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Main_menu/Settings_button)

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Main_menu/Main_exit_button)
	await $Click_sound.finished
	#await get_tree().create_timer(0.2)
	get_tree().quit()

func _on_play_back_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Play_menu/Back_button)
	alternate_main_menu()
	alternate_play_menu()

func _on_jam_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Play_menu/Jam_button)
	alternate_play_menu()
	alternate_jam_menu()
	$Label_gamemode.text = "Jam:"

func _on_local_jam_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_jam/Local_jam_button)
	$Label_gamemode.visible = false
	$Background.texture = load("res://assets/sprites/fondo1-ajustado.png")
	$Local_menu_jam.visible = !$Local_menu_jam.visible
	$Local_customizer.show()
	alternate_jam_menu()

func _on_local_jam_back_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Local_menu_jam/Back_button)
	$Local_menu_jam.visible = !$Local_menu_jam.visible
	$Local_customizer.hide()
	$Background.texture = load("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	$Label_gamemode.visible = true
	alternate_jam_menu()

func _on_start_local_jam_button_pressed() -> void: 
	$Click_sound.play()
	await button_press_animation($Local_menu_jam/Start_local_jam_button)
	await $Click_sound.finished
	get_tree().change_scene_to_file("res://scenes/local_jam.tscn")

func _on_lan_jam_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_jam/LAN_jam_button)
	alternate_jam_lan_menu()
	alternate_jam_menu()
	$Online_customizer.show()

func _on_lan_jam_menu_back_button_pressed() -> void:
	is_host = false
	$Click_sound.play()
	await button_press_animation($LAN_menu_jam/Back_button)
	$LAN_menu_jam/Start_game_button/Label.text = ""
	NetworkManager.reset_connections()
	disable_start_buttons()
	alternate_jam_lan_menu()
	alternate_jam_menu()
	$Online_customizer.hide()

func _on_lan_jam_host_button_pressed() -> void:
	is_host = true
	$Click_sound.play()
	await button_press_animation($LAN_menu_jam/Host_button)
	notifications.hosting_N()
	LANNetworkManager.receive_player_info($LAN_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_jam/Ip_adress.text == "":
		$LAN_menu_jam/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_jam/Port.text == "":
		$LAN_menu_jam/Port.text = "22022"
	
	#LANNetworkManager.is_hosting = true
	LANNetworkManager.host_game($LAN_menu_jam/Ip_adress.text, $LAN_menu_jam/Port.text)


func _on_lan_jam_join_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($LAN_menu_jam/Join_button)
	
	is_host = false
	LANNetworkManager.receive_player_info($LAN_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_jam/Ip_adress.text == "":
		$LAN_menu_jam/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_jam/Port.text == "":
		$LAN_menu_jam/Port.text = "22022"
	
	LANNetworkManager.join_game($LAN_menu_jam/Ip_adress.text, $LAN_menu_jam/Port.text)

func _on_start_lan_jam_game_button_pressed() -> void:
	if !$LAN_menu_jam/Start_game_button.disabled:
		$Click_sound.play()
		await button_press_animation($LAN_menu_jam/Start_game_button)
		await $Click_sound.finished
	
	if !multiplayer.is_server() or LANNetworkManager.players.size() != 2: # or multiplayer.get_peers().size() != 2
		return
	LANNetworkManager.start_lan_jam.rpc()

func _on_online_jam_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_jam/Online_jam_button)
	
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible
	$Online_menu_jam.visible = !$Online_menu_jam.visible
	$Online_customizer.show()

func _on_online_jam_host_button_pressed():
	$Click_sound.play()
	await button_press_animation($Online_menu_jam/Host_button)
	
	if NetworkManager.noray_copy == "":
		print("Noray server is down")
		notifications.server_down_N()
		return
		
	notifications.hosting_N()
	is_host = true
	online_scored = false

	disable_start_buttons()
	NetworkManager.receive_player_info($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index])
	NetworkManager.host()

func _on_online_jam_join_button_pressed():
	if !$Online_menu_jam/Join_button.disabled:
		$Click_sound.play()
		await button_press_animation($Online_menu_jam/Join_button)
	
	if NetworkManager.noray_copy == "":
		print("Noray server is down")
		notifications.server_down_N()
		return
	
	is_host = false
	
	disable_join_buttons()
	disable_start_buttons()
	NetworkManager.join($Online_menu_jam/OID_input.text)
	await multiplayer.connected_to_server
	
	NetworkManager.send_player_info.rpc($Online_menu_jam/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())

func _on_online_jam_start_button_pressed():
	if !$Online_menu_jam/Start_game_button.disabled:
		$Click_sound.play()
		await button_press_animation($Online_menu_jam/Start_game_button)
		await $Click_sound.finished
	
	if !multiplayer.is_server() or NetworkManager.players.size() != 2:
		return
	NetworkManager.start_online_jam.rpc()
	print("Start")

func _on_online_jam_menu_copy_button_pressed():
	DisplayServer.clipboard_set(Noray.oid)

func _on_online_jam_menu_delete_button_pressed() -> void:
	$Online_menu_jam/OID_input.text = ""

func _on_online_jam_menu_recover_button_pressed() -> void:
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy

func _on_online_jam_menu_back_button_pressed():
	is_host = false
	
	lobby_ui.reset_ui()
	NetworkManager.reset_connections()
	disable_start_buttons()
	enable_join_buttons()
	$Click_sound.play()
	await button_press_animation($Online_menu_jam/Back_button)
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible
	$Online_menu_jam.visible = !$Online_menu_jam.visible
	$Online_customizer.hide()

func _on_jam_menu_back_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_jam/Back_button)
	alternate_jam_menu()
	alternate_play_menu()
	$Label_gamemode.text = ""

func _on_scored_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Play_menu/Scored_button)
	alternate_play_menu()
	alternate_scored_menu()
	$Label_gamemode.text = "Scored:"

func _on_local_scored_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_scored/Local_scored_button)
	$Label_gamemode.visible = false
	$Background.texture = load("res://assets/sprites/fondo1-ajustado.png")
	$Local_menu_scored.visible = !$Local_menu_scored.visible
	$Local_customizer.show()
	alternate_scored_menu()

func _on_local_scored_menu_back_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Local_menu_scored/Back_button)
	$Label_gamemode.visible = true
	$Background.texture = load("res://assets/sprites/fondo1-con-titulo3-aplanado3.png")
	$Local_menu_scored.visible = !$Local_menu_scored.visible
	$Local_customizer.hide()
	alternate_scored_menu()

func _on_start_local_scored_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Local_menu_scored/Start_game_button)
	await $Click_sound.finished
	get_tree().change_scene_to_file("res://scenes/local_multiplayer.tscn")

func _on_lan_scored_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_scored/Lan_scored_button)
	alternate_scored_menu()
	$LAN_menu_scored.visible = !$LAN_menu_scored.visible
	$Online_customizer.show()

func _on_lan_scored_menu_back_button_pressed() -> void:
	is_host = false
	$Click_sound.play()
	await button_press_animation($LAN_menu_scored/Back_button)
	$LAN_menu_scored/Start_game_button/Label.text = ""
	NetworkManager.reset_connections()
	disable_start_buttons()
	alternate_scored_menu()
	$LAN_menu_scored.visible = !$LAN_menu_scored.visible
	$Online_customizer.hide()

func _on_lan_scored_host_button_pressed() -> void:
	is_host = true
	$Click_sound.play()
	await button_press_animation($LAN_menu_scored/Host_button)
	notifications.hosting_N()
	LANNetworkManager.receive_player_info($LAN_menu_scored/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_scored/Ip_adress.text == "":
		$LAN_menu_scored/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_scored/Port.text == "":
		$LAN_menu_scored/Port.text = "22022"
	
	LANNetworkManager.host_game($LAN_menu_scored/Ip_adress.text, $LAN_menu_scored/Port.text)


func _on_lan_scored_join_button_pressed() -> void:
	is_host = false
	$Click_sound.play()
	await button_press_animation($LAN_menu_scored/Join_button)
	LANNetworkManager.receive_player_info($LAN_menu_scored/Player_name.text, Global.local_player1_skin[Global.index])
	
	if $LAN_menu_scored/Ip_adress.text == "":
		$LAN_menu_scored/Ip_adress.text = "192.168.56.1"
	
	if $LAN_menu_scored/Port.text == "":
		$LAN_menu_scored/Port.text = "22022"
	
	LANNetworkManager.join_game($LAN_menu_scored/Ip_adress.text, $LAN_menu_scored/Port.text)

func _on_start_lan_scored_game_button_pressed() -> void:
	if !$Online_menu_scored/Start_game_button.disabled:
		$Click_sound.play()
		await button_press_animation($Online_menu_scored/Start_game_button)
		await $Click_sound.finished
	
	if !multiplayer.is_server() or LANNetworkManager.players.size() != 2:
		return
	LANNetworkManager.start_lan_scored.rpc()

func _on_online_scored_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_scored/Online_scored_button)
	$Online_menu_scored/OID_input.text = NetworkManager.noray_copy
	$Mode_menu_scored.visible = !$Mode_menu_scored.visible
	$Online_menu_scored.visible = !$Online_menu_scored.visible
	$Online_customizer.show()

func _on_online_scored_host_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Online_menu_scored/Host_button)
	
	if NetworkManager.noray_copy == "":
		print("Noray server is down")
		notifications.server_down_N()
		return
	
	notifications.hosting_N()
	request_online_scored_host()

func _on_online_scored_join_button_pressed() -> void:
	if !$Online_menu_scored/Join_button.disabled:
		$Click_sound.play()
		await button_press_animation($Online_menu_scored/Join_button)
	
	if $Online_menu_scored/OID_input.text == Noray.oid:
		print("Own OID error")
		notifications.connection_join_error_N()
		return
	
	if NetworkManager.noray_copy == "":
		print("Noray server is down")
		notifications.server_down_N()
		return
	
	is_host = false
	online_scored = true
	
	lobby_ui.reset_ui()
	disable_join_buttons()
	disable_start_buttons()
	
	NetworkManager.receive_player_info($Online_menu_scored/Player_name.text, Global.local_player1_skin[Global.index])
	NetworkManager.join($Online_menu_scored/OID_input.text)
	#print("Awaiting connected_to_server...")
	#await multiplayer.connected_to_server
	#print("Conected!")
	
	#NetworkManager.send_player_info.rpc($Online_menu_scored/Player_name.text, Global.local_player1_skin[Global.index], multiplayer.get_unique_id())

func _on_online_scored_start_button_pressed() -> void:
	if !$Online_menu_scored/Start_game_button.disabled:
		$Click_sound.play()
		await button_press_animation($Online_menu_scored/Start_game_button)
		await $Click_sound.finished
	
	if !multiplayer.is_server() or NetworkManager.players.size() != 2:
		return
	NetworkManager.start_online_scored.rpc()

func _on_online_scored_menu_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)

func _on_online_scored_menu_delete_button_pressed() -> void:
	$Online_menu_scored/OID_input.text = ""

func _on_online_scored_menu_recover_button_pressed() -> void:
	$Online_menu_scored/OID_input.text = NetworkManager.noray_copy

func _on_online_scored_menu_back_button_pressed() -> void:
	is_host = false
	online_scored = false

	$Click_sound.play()
	await button_press_animation($Online_menu_scored/Back_button)
	
	lobby_ui.reset_ui()
	NetworkManager.reset_connections()
	disable_start_buttons()
	enable_join_buttons()
	
	$Mode_menu_scored.visible = !$Mode_menu_scored.visible
	$Online_menu_scored.visible = !$Online_menu_scored.visible
	$Online_customizer.hide()

func _on_scored_menu_back_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Mode_menu_scored/Back_button)
	alternate_scored_menu()
	alternate_play_menu()
	$Label_gamemode.text = ""

func _on_sound_button_pressed() -> void:
	if sound_on:
		AudioServer.set_bus_mute(1, true)
		$Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido2-ajustado.png")
	else:
		AudioServer.set_bus_mute(1, false)
		$Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido1-ajustado.png")
	
	sound_on = !sound_on

func ready_to_start():
	if is_host:
		if online_scored:
			$Online_menu_scored/Start_game_button.disabled = false
			$Online_menu_scored/Start_game_button.texture_normal = preload("res://assets/sprites/boton1-start-ready.png")
			$Online_menu_scored/Label_start.text = "Ready to start!"
		else:
			$Online_menu_jam/Start_game_button.disabled = false
			$Online_menu_jam/Start_game_button.texture_normal = preload("res://assets/sprites/boton1-start-ready.png")
			$Online_menu_jam/Label_start.text = "Ready to start!"
	else:
		if online_scored:
			$Online_menu_scored/Label_start.text = "Waiting for the host to start"
		else:
			$Online_menu_jam/Label_start.text = "Waiting for the host to start"

func disable_start_buttons():
	$Online_menu_jam/Start_game_button.disabled = true
	$Online_menu_scored/Start_game_button.disabled = true
	$Online_menu_jam/Start_game_button.texture_normal = preload("res://assets/sprites/boton1-start-blocked.png")
	$Online_menu_scored/Start_game_button.texture_normal = preload("res://assets/sprites/boton1-start-blocked.png")
	$Online_menu_jam/Label_start.text = ""
	$Online_menu_scored/Label_start.text = ""

func disable_join_buttons():
	$Online_menu_jam/Join_button.disabled = true
	$Online_menu_scored/Join_button.disabled = true
	$Online_menu_jam/Join_button.texture_normal = preload("res://assets/sprites/boton1-join-blocked.png")
	$Online_menu_scored/Join_button.texture_normal = preload("res://assets/sprites/boton1-join-blocked.png")

func enable_join_buttons():
	$Online_menu_jam/Join_button.disabled = false
	$Online_menu_scored/Join_button.disabled = false
	$Online_menu_jam/Join_button.texture_normal = preload("res://assets/sprites/boton1-join.png")
	$Online_menu_scored/Join_button.texture_normal = preload("res://assets/sprites/boton1-join.png")

func _on_reset_noray_button_pressed() -> void:
	await NetworkManager.reset_noray()
	
	$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
	$Online_menu_scored/OID_input.text = NetworkManager.noray_copy

func player_joined(id):
	print("Peer " + str(id) + " has joined")
	notifications.player_connected_N(id) 

func player_disconnected(id):
	await notifications.player_disconnected_N(id)
	
	if multiplayer.is_server():
		NetworkManager.reset_connections()
		request_online_scored_host()
		lobby_ui.update_ui(id)
	else:
		lobby_ui.reset_ui()
		NetworkManager.reset_connections()
	
	disable_start_buttons()
	enable_join_buttons()
	
func update_lobby(id):
	lobby_ui.update_ui(id)

func request_online_scored_host():
	is_host = true
	online_scored = true

	disable_start_buttons()
	NetworkManager.receive_player_info($Online_menu_scored/Player_name.text, Global.local_player1_skin[Global.index])
	NetworkManager.host()

func _on_noray_server_check_button_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		NetworkManager.noray_adress = "tomfol.io"
		await NetworkManager.reset_noray()
		$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
		$Online_menu_scored/OID_input.text = NetworkManager.noray_copy
	else:
		NetworkManager.noray_adress = "51.170.42.210"
		await NetworkManager.reset_noray()
		$Online_menu_jam/OID_input.text = NetworkManager.noray_copy
		$Online_menu_scored/OID_input.text = NetworkManager.noray_copy

func button_press_animation(button: Control):
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	var tween = create_tween()
	var original_position = button.position
	
	tween.tween_property(button, "position", original_position + Vector2(0, 10), 0.15)
	tween.tween_property(button, "position", original_position, 0.15)
	
	await tween.finished
	
	playing = false
