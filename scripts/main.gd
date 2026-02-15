extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func alternate_main_menu():
	$Main_menu.visible = !$Main_menu.visible

func alternate_play_menu():
	$Play_menu.visible = !$Play_menu.visible

func alternate_jam_menu():
	$Mode_menu_jam.visible = !$Mode_menu_jam.visible

func alternate_jam_online_menu():
	$Online_menu_jam.visible = !$Online_menu_jam.visible

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
	alternate_play_menu()
	alternate_jam_menu()

func _on_local_jam_button_pressed() -> void:
	$Click_sound.play()
	await get_tree().create_timer(0.2)
	get_tree().change_scene_to_file("res://scenes/local_jam.tscn")

func _on_online_jam_button_pressed() -> void:
	alternate_jam_online_menu()
	alternate_jam_menu()

func _on_jam_menu_back_button_pressed() -> void:
	alternate_jam_menu()
	alternate_play_menu()

func _on_online_jam_menu_back_button_pressed() -> void:
	alternate_jam_online_menu()
	alternate_jam_menu()

func _on_host_button_pressed() -> void:
	NetworkManager.start_server()
	get_tree().change_scene_to_file("res://scenes/online_jam.tscn")

func _on_join_button_pressed() -> void:
	NetworkManager.start_client()
	get_tree().change_scene_to_file("res://scenes/online_jam.tscn")
