extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if $CanvasLayer.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$CanvasLayer.visible = !$CanvasLayer.visible
		get_tree().paused = !get_tree().paused
		

func _on_resume_button_pressed() -> void:
	get_tree().paused = !get_tree().paused
	$CanvasLayer.visible = !$CanvasLayer.visible

func _on_exit_button_pressed() -> void:
	get_tree().paused = !get_tree().paused
	get_tree().change_scene_to_file("res://scenes/main.tscn")
