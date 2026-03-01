extends Node


func _ready() -> void:
	show_skin()
	hide()

func show_skin():
	$CanvasLayer/Skins.play(Global.local_player1_skin[Global.index])

func _on_left_button_pressed() -> void:
	if Global.index > 0:
		Global.index -= 1
		show_skin()
	
func _on_right_button_pressed() -> void:
	if Global.index < Global.local_player1_skin.size() - 1:
		Global.index += 1
		show_skin()

func show():
	$CanvasLayer.visible = true

func hide():
	$CanvasLayer.visible = false
