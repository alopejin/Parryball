extends Node


signal out_of_settings

@onready var notifications = $Notifications

var playing = false

var action = ""

func _ready() -> void:
	Global.window_set.connect(initial_window)
	
	show_controls()
	
	$Menu.visible = false
	$Menu_game.visible = false
	$Menu_sound.visible = false
	$Menu_controls.visible = false
	
	$Menu_game/HSlider_Brightness.value = GlobalWorldEnvironment.environment.adjustment_brightness
	
	$Menu_sound/HSlider_Master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	$Menu_sound/HSlider_Music.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	$Menu_sound/HSlider_SFX.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	if Global.ball_trail_on:
		$Menu_game/CheckBox_ball_trail.button_pressed = true
	else:
		$Menu_game/CheckBox_ball_trail.button_pressed = false
	
	if Global.point_effect_on:
		$Menu_game/CheckBox_point_effect.button_pressed = true
	else:
		$Menu_game/CheckBox_point_effect.button_pressed = false

func alternate_main_menu():
	$Menu.visible = !$Menu.visible

func alternate_game_menu():
	$Menu_game.visible = !$Menu_game.visible

func alternate_sound_menu():
	$Menu_sound.visible = !$Menu_sound.visible

func alternate_controls_menu():
	$Menu_controls.visible = !$Menu_controls.visible 

func _on_game_button_pressed():
	$Click_sound.play()
	
	if !$Menu_game.visible:
		await button_press_animation($Menu/Game_button)
	else:
		await button_press_animation($Menu_game/Back_button)
	
	alternate_main_menu()
	alternate_game_menu()

func _on_sound_button_pressed():
	$Click_sound.play()
	
	if !$Menu_sound.visible:
		await button_press_animation($Menu/Sound_button)
	else:
		await button_press_animation($Menu_sound/Back_button)
	
	alternate_main_menu()
	alternate_sound_menu()

func _on_controls_button_pressed():
	$Click_sound.play()
	
	if !$Menu_controls.visible:
		await button_press_animation($Menu/Controls_button)
	else:
		await button_press_animation($Menu_controls/Back_button)
	
	alternate_main_menu()
	alternate_controls_menu()

func _on_back_button_pressed():
	$Click_sound.play()
	await button_press_animation($Menu/Back_button)
	
	$Menu.visible = false
	$Menu_game.visible = false
	$Menu_sound.visible = false
	
	out_of_settings.emit()

func _on_brightness_slider_value_changed(value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_brightness = value

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func toggle_ball_trail(toggled_on: bool) -> void:
	if toggled_on:
		Global.ball_trail_on = true
	else:
		Global.ball_trail_on = false

func toggle_point_effect(toggled_on: bool) -> void:
	if toggled_on:
		Global.point_effect_on = true
	else:
		Global.point_effect_on = false

func window_mode(toggled_on: bool) -> void:
	if toggled_on:
		get_window().set_mode(Window.MODE_WINDOWED)
		#get_window().size = Vector2i(1280, 720)
		get_window().move_to_center()
	else:
		get_window().set_mode(Window.MODE_FULLSCREEN)

func initial_window():
	if get_window().mode == Window.MODE_WINDOWED:
		$Menu_game/CheckBox_window_mode.button_pressed = true
	else:
		$Menu_game/CheckBox_window_mode.button_pressed = false

func key_to_string(event: String):
	var events = InputMap.action_get_events(event)
	var key = null
	var key_name = ""
	
	for ev in events:
		if ev is InputEventKey:
			key = ev.physical_keycode
			break 
		elif ev is InputEventMouseButton:
			key_name = mouse_button_to_string(ev.button_index)
			return key_name
	
	if key != null:
		key_name = OS.get_keycode_string(key)
	else:
		key_name = "'None'"
	
	return key_name

func mouse_button_to_string(button_index: int) -> String:
	if button_index == MOUSE_BUTTON_LEFT:
		return "Mouse Left"
	if button_index == MOUSE_BUTTON_RIGHT:
		return "Mouse Right"
	if button_index == MOUSE_BUTTON_MIDDLE:
		return "Mouse Middle"
	if button_index == MOUSE_BUTTON_WHEEL_UP:
		return "Mouse Wheel Up"
	if button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return "Mouse Wheel Down"
	
	return "Mouse Button " + str(button_index)

func show_controls():
	$Menu_controls/Label_Player1_Local/Label_controls.text = "Move left: " + key_to_string("left-p1") + "\n" + "Move right: " + key_to_string("right-p1") + "\n" + "Jump: " + key_to_string("jump-p1") + "\n" + "Parry: " + key_to_string("parry-p1") + "\n" + "Serve: " + key_to_string("serve-p1") + "\n"
	$Menu_controls/Label_Player2_Local/Label_controls.text = "Move left: " + key_to_string("left-p2") + "\n" + "Move right: " + key_to_string("right-p2") + "\n" + "Jump: " + key_to_string("jump-p2") + "\n" + "Parry: " + key_to_string("parry-p2") + "\n" + "Serve: " + key_to_string("serve-p2") + "\n"
	$Menu_controls/Label_Multiplayer/Label_controls.text = "Move left: " + key_to_string("left") + "\n" + "Move right: " + key_to_string("right") + "\n" + "Jump: " + key_to_string("jump") + "\n" + "Parry: " + key_to_string("parry") + "\n" + "Serve: " + key_to_string("serve") + "\n"

func _on_button_new_action_leftp1_pressed() -> void:
	action = "left-p1"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_leftp1_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_A
	InputMap.action_erase_events("left-p1")
	InputMap.action_add_event("left-p1", event)
	
	show_controls()

func _on_button_new_action_rightp1_pressed() -> void:
	action = "right-p1"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_rightp1_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_D
	InputMap.action_erase_events("right-p1")
	InputMap.action_add_event("right-p1", event)
	
	show_controls()

func _on_button_new_action_jumpp1_pressed() -> void:
	action = "jump-p1"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_jumpp1_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_W
	InputMap.action_erase_events("jump-p1")
	InputMap.action_add_event("jump-p1", event)
	
	show_controls()

func _on_button_new_action_parryp1_pressed() -> void:
	action = "parry-p1"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_parryp1_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_T
	InputMap.action_erase_events("parry-p1")
	InputMap.action_add_event("parry-p1", event)
	
	show_controls()

func _on_button_new_action_servep1_pressed() -> void:
	action = "serve-p1"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_servep1_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_E
	InputMap.action_erase_events("serve-p1")
	InputMap.action_add_event("serve-p1", event)
	
	show_controls()

func _on_button_new_action_leftp2_pressed() -> void:
	action = "left-p2"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_leftp2_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_LEFT
	InputMap.action_erase_events("left-p2")
	InputMap.action_add_event("left-p2", event)
	
	show_controls()

func _on_button_new_action_rightp2_pressed() -> void:
	action = "right-p2"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_rightp2_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_RIGHT
	InputMap.action_erase_events("right-p2")
	InputMap.action_add_event("right-p2", event)
	
	show_controls()

func _on_button_new_action_jumpp2_pressed() -> void:
	action = "jump-p2"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_jumpp2_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_UP
	InputMap.action_erase_events("jump-p2")
	InputMap.action_add_event("jump-p2", event)
	
	show_controls()

func _on_button_new_action_parryp2_pressed() -> void:
	action = "parry-p2"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_parryp2_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_ENTER
	InputMap.action_erase_events("parry-p2")
	InputMap.action_add_event("parry-p2", event)
	
	show_controls()

func _on_button_new_action_servep2_pressed() -> void:
	action = "serve-p2"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_servep2_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_MINUS
	InputMap.action_erase_events("serve-p2")
	InputMap.action_add_event("serve-p2", event)
	
	show_controls()

func _on_button_new_action_left_pressed() -> void:
	action = "left"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_left_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_A
	InputMap.action_erase_events("left")
	InputMap.action_add_event("left", event)
	
	show_controls()

func _on_button_new_action_right_pressed() -> void:
	action = "right"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_right_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_D
	InputMap.action_erase_events("right")
	InputMap.action_add_event("right", event)
	
	show_controls()

func _on_button_new_action_jump_pressed() -> void:
	action = "jump"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_jump_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_W
	InputMap.action_erase_events("jump")
	InputMap.action_add_event("jump", event)
	
	show_controls()

func _on_button_new_action_parry_pressed() -> void:
	action = "parry"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_parry_pressed() -> void:
	var event = InputEventMouseButton.new()
	
	event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_erase_events("parry")
	InputMap.action_add_event("parry", event)
	
	show_controls()

func _on_button_new_action_serve_pressed() -> void:
	action = "serve"
	Global.setting_key = true
	notifications.change_key_N()

func _on_button_reset_action_serve_pressed() -> void:
	var event = InputEventKey.new()
	
	event.physical_keycode = KEY_E
	InputMap.action_erase_events("serve")
	InputMap.action_add_event("serve", event)
	
	show_controls()

func _input(event: InputEvent) -> void:
	if !Global.setting_key:
		return
	
	if event.is_pressed():
		if event is InputEventKey:
			if event.physical_keycode == KEY_ESCAPE:
				Global.setting_key = false
				return
			
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
				
			Global.setting_key = false
				
			show_controls()
		elif event is InputEventMouseButton:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
			
			Global.setting_key = false
			
			show_controls()

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
