extends Node


var parent = null
var sound_on = true
var playing = false

func _ready() -> void:
	await get_tree().process_frame
	parent = get_parent().name

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if $CanvasLayer.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			if parent == "Local_jam" or parent == "Local_multiplayer":
				$CanvasLayer/Pause_label.text = "Game paused"
			else:
				$CanvasLayer/Pause_label.text = ""
			
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		$CanvasLayer.visible = !$CanvasLayer.visible
		
		if parent == "Local_jam" or parent == "Local_multiplayer":
			get_tree().paused = !get_tree().paused
		

func _on_resume_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($CanvasLayer/Resume_button)
	
	if parent == "Local_jam" or parent == "Local_multiplayer":
		get_tree().paused = !get_tree().paused
	$CanvasLayer.visible = !$CanvasLayer.visible

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($CanvasLayer/Exit_button)
	await $Click_sound.finished
	
	get_tree().paused = false
	
	if !parent == "Local_jam" and !parent == "Local_multiplayer":
		NetworkManager.reset_connections()
		NetworkManager.join_available.emit()
	
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_sound_button_pressed() -> void:
	$Click_sound.play()
	
	if sound_on:
		AudioServer.set_bus_mute(1, true)
		$CanvasLayer/Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido2-ajustado.png")
	else:
		AudioServer.set_bus_mute(1, false)
		$CanvasLayer/Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido1-ajustado.png")
	
	sound_on = !sound_on

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
