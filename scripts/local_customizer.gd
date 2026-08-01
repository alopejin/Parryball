extends Node


func _ready() -> void:
	$Player1_canvas/Player1_name.text = Global.local_player1_name
	$Player2_canvas/Player2_name.text = Global.local_player2_name
	show_skin()
	hide()

func show_skin():
	$Player1_canvas/Skins.play(Global.local_player1_skin[Global.index])
	$Player2_canvas/Skins.play(Global.local_player2_skin[Global.index_player2])

func _on_player1_left_button_pressed() -> void:
	if Global.index > 0:
		Global.index -= 1
		show_skin()
	else:
		Global.index = Global.local_player1_skin.size() - 1
		show_skin()

func _on_player1_right_button_pressed() -> void:
	if Global.index < Global.local_player1_skin.size() - 1:
		Global.index += 1
		show_skin()
	else:
		Global.index = 0
		show_skin()

func _on_player2_left_button_pressed() -> void:
	if Global.index_player2 > 0:
		Global.index_player2 -= 1
		show_skin()
	else:
		Global.index_player2 = Global.local_player2_skin.size() - 1
		show_skin()

func _on_player2_right_button_pressed() -> void:
	if Global.index_player2 < Global.local_player2_skin.size() - 1:
		Global.index_player2 += 1
		show_skin()
	else:
		Global.index_player2 = 0
		show_skin()

func _on_player_1_name_text_changed(new_text: String) -> void:
	Global.local_player1_name = new_text

func _on_player_2_name_text_changed(new_text: String) -> void:
	Global.local_player2_name = new_text

func show():
	$Player1_canvas.visible = true
	$Player2_canvas.visible = true

func hide():
	$Player1_canvas.visible = false
	$Player2_canvas.visible = false
