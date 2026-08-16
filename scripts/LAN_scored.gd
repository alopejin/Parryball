extends Node2D


@onready var ball = preload("res://scenes/ball_online.tscn")

var player1: CharacterBody2D
var player2: CharacterBody2D
var player_online = preload("res://scenes/player-online.tscn")

var score1 = 0
var score2 = 0
var active_ball
var game_active = false

var playing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	disable_buttons()
	var index = 0
	
	for player in LANNetworkManager.players:
		var current_player = player_online.instantiate()
		current_player.name = str(LANNetworkManager.players[player].id)
		add_child(current_player)
		
		if player1 == null:
			player1 = current_player
		else:
			player2 = current_player
			
		current_player.set_multiplayer_authority(LANNetworkManager.players[player].id)
		current_player.get_node("Name").text = LANNetworkManager.players[player].name
		current_player.get_node("Skins").play(LANNetworkManager.players[player].skin)
		
		for spawn in get_tree().get_nodes_in_group("Spawn"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
		index += 1
	
	print("Players size: " + str(LANNetworkManager.players.size()))
	if multiplayer.is_server():
		start_game()

func start_game():
	game_active = true
	decide_serve()
	create_ball.rpc()

#@rpc("authority")
func decide_serve():
	if randf() > 0.5:
		#active_ball.spawn(player2.global_position + Vector2(0, -50))
		LANNetworkManager.player1_serves = false
		#p2_serves.rpc()
	else:
		#active_ball.spawn(player1.global_position + Vector2(0, -50))
		LANNetworkManager.player1_serves = true
		#p1_serves.rpc()
	
	sync_state.rpc(score1, score2, LANNetworkManager.player1_serves)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	show_score()
	
	if multiplayer.is_server() and active_ball != null:
		if !active_ball.served:
			if LANNetworkManager.player1_serves:
				active_ball.spawn(player1.global_position + Vector2(0, -50))
			else:
				active_ball.spawn(player2.global_position + Vector2(0, -50))

func _on_score_counter_body_entered(body: RigidBody2D) -> void:
	if !multiplayer.is_server():
		return
	if !body.is_in_group("ball"):
		return
	if body != active_ball:
		return
		
	if body.global_position.x < $Net/Sprite2D.global_position.x:
		score2 += 1
		LANNetworkManager.player1_serves = false
	else:
		score1 += 1
		LANNetworkManager.player1_serves = true
			
	play_score_sound.rpc()
	sync_state.rpc(score1, score2, LANNetworkManager.player1_serves)
	reset_ball()

	if score1 == 10 or score2 == 10:
		show_victory.rpc()

@rpc("authority", "call_local")
func create_ball():
	var b = ball.instantiate()
	b.name = "Ball"
	add_child(b)
	active_ball = b
	
	if multiplayer.is_server():
		reset_ball()

@rpc("authority", "call_local")
func play_score_sound():
	$Score_sound.play()

@rpc("authority")
func sync_state(s1, s2, p1_serves):
	score1 = s1
	score2 = s2
	LANNetworkManager.player1_serves = p1_serves

func reset_ball():
	if !multiplayer.is_server():
		return
	if active_ball == null:
		return
		
	active_ball.sync_served.rpc(false)
	active_ball.linear_velocity = Vector2.ZERO
	active_ball.angular_velocity = 0.0
	
	if LANNetworkManager.player1_serves:
		active_ball.spawn(player1.global_position + Vector2(0, -50))
	else:
		active_ball.spawn(player2.global_position + Vector2(0, -50))

func show_score():
	$Score_P1.text = str(score1)
	$Score_P2.text = str(score2)

@rpc("authority", "call_local")
func show_victory():
	await get_tree().create_timer(0.1)
	
	if score1 == 10:
		$Winner_label.text = player1.get_node("Name").text  + " wins !"
	else:
		$Winner_label.text = player2.get_node("Name").text  + " wins !"
	
	#$Pause.PROCESS_MODE_DISABLED
	$Victory_sound.play()
	get_tree().paused = true
	show_score()
	enable_buttons()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func disable_buttons():
	$Play_again_button.disabled = true
	$Play_again_button.visible = false
	$Exit_button.disabled = true
	$Exit_button.visible = false

func enable_buttons():
	$Play_again_button.disabled = false
	$Play_again_button.visible = true
	$Exit_button.disabled = false
	$Exit_button.visible = true

func _on_play_again_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Play_again_button)
	await $Click_sound.finished
	
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Exit_button)
	await $Click_sound.finished
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func button_press_animation(button: Control):
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	var tween = create_tween()
	var original_position = button.position
	
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "position", original_position + Vector2(0, 10), 0.15)
	tween.tween_property(button, "position", original_position, 0.15)
	
	await tween.finished
	
	playing = false
