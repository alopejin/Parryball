extends Node


var sound_on = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if $CanvasLayer.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$CanvasLayer.visible = !$CanvasLayer.visible
		if get_parent().name != "Online_jam":
			get_tree().paused = !get_tree().paused
		

func _on_resume_button_pressed() -> void:
	get_tree().paused = !get_tree().paused
	$CanvasLayer.visible = !$CanvasLayer.visible

func _on_exit_button_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = !get_tree().paused
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_sound_button_pressed() -> void:
	if sound_on:
		AudioServer.set_bus_mute(1, true)
		$CanvasLayer/Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido2-ajustado.png")
	else:
		AudioServer.set_bus_mute(1, false)
		$CanvasLayer/Sound_button.texture_normal = preload("res://assets/sprites/boton_sonido1-ajustado.png")
	
	sound_on = !sound_on
	
