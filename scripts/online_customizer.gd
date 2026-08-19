extends Node


var playing

func _ready() -> void:
	Global.skin_changed.connect(show_skin)
	show_skin()
	hide()

func show_skin():
	$CanvasLayer/Skins.play(Global.local_player1_skin[Global.index])

func _on_left_button_pressed() -> void:
	button_press_animation($CanvasLayer/Left_button)
	
	if Global.index > 0:
		Global.index -= 1
		show_skin()
	else:
		Global.index = Global.local_player1_skin.size() - 1
		show_skin()
	
	Global.skin_changed.emit()

func _on_right_button_pressed() -> void:
	button_press_animation($CanvasLayer/right_button)
	
	if Global.index < Global.local_player1_skin.size() - 1:
		Global.index += 1
		show_skin()
	else:
		Global.index = 0
		show_skin()
	
	Global.skin_changed.emit()

func show():
	$CanvasLayer.visible = true

func hide():
	$CanvasLayer.visible = false

func button_press_animation(button: Control):
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	var tween = create_tween()
	var original_position = button.position
	
	tween.tween_property(button, "position", original_position + Vector2(0, 5), 0.15)
	tween.tween_property(button, "position", original_position, 0.15)
	
	await tween.finished
	
	playing = false
