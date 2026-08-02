extends Node2D


@onready var ball = preload("res://scenes/ball_online.tscn")
@onready var notifications = $Notifications
@onready var label_player = $Label_player

var player1: CharacterBody2D
var player2: CharacterBody2D
var player_online = preload("res://scenes/player-online.tscn")

var score1 = 0
var score2 = 0
var active_ball
var playing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	
	NetworkManager.votes_updated.connect(update_votes)
	multiplayer.peer_disconnected.connect(player_disconnected)
	
	$Pause.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	$Label.text = ""
	$Play_again_button.texture_normal = preload("res://assets/sprites/boton1-play_again.png")
	label_player.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	label_player.text = ""
	
	disable_buttons()
	
	var index = 0
	
	for player in NetworkManager.players:
		var current_player = player_online.instantiate()
		current_player.name = str(NetworkManager.players[player].id)
		add_child(current_player)
		
		if player1 == null:
			player1 = current_player
		else:
			player2 = current_player
			
		current_player.set_multiplayer_authority(NetworkManager.players[player].id)
		current_player.get_node("Name").text = NetworkManager.players[player].name
		current_player.get_node("Skins").play(NetworkManager.players[player].skin)
		
		for spawn in get_tree().get_nodes_in_group("Spawn"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
		index += 1
	
	print("Players size: " + str(NetworkManager.players.size()))
	if multiplayer.is_server():
		start_game()

func start_game():
	decide_serve()
	create_ball.rpc()
	print("Game on")

func decide_serve():
	if randf() > 0.5:
		NetworkManager.player1_serves = false
	else:
		NetworkManager.player1_serves = true
	
	sync_state.rpc(score1, score2, NetworkManager.player1_serves)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	show_score()
	
	if multiplayer.is_server() and active_ball != null:
		if !active_ball.served:
			if NetworkManager.player1_serves:
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
		NetworkManager.player1_serves = false
	else:
		score1 += 1
		NetworkManager.player1_serves = true
	
	play_score_sound.rpc()
	sync_state.rpc(score1, score2, NetworkManager.player1_serves)
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
	NetworkManager.player1_serves = p1_serves

func reset_ball():
	if !multiplayer.is_server():
		return
	if active_ball == null:
		return
		
	active_ball.sync_served.rpc(false)
	active_ball.linear_velocity = Vector2.ZERO
	active_ball.angular_velocity = 0.0
	
	if NetworkManager.player1_serves:
		active_ball.spawn(player1.global_position + Vector2(0, -50))
	else:
		active_ball.spawn(player2.global_position + Vector2(0, -50))

func show_score():
	$Score_P1.text = str(score1)
	$Score_P2.text = str(score2)

@rpc("authority", "call_local")
func show_victory():
	if score1 == 10:
		if !player1.get_node("Name").text == "":
			$Winner_label.text = player1.get_node("Name").text  + " wins !"
		else:
			$Winner_label.text = "Player 1 wins !"
	else:
		if !player2.get_node("Name").text == "":
			$Winner_label.text = player2.get_node("Name").text  + " wins !"
		else:
			$Winner_label.text = "Player 2 wins !"
	
	$Pause.process_mode = Node.PROCESS_MODE_DISABLED
	active_ball.hide_trail()
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
	
	if !NetworkManager.has_voted:
		NetworkManager.has_voted = true
		if multiplayer.is_server():
			NetworkManager.request_vote(1)
		else:
			NetworkManager.request_vote.rpc_id(1, 1)
	else:
		NetworkManager.has_voted = false
		
		if multiplayer.is_server():
			NetworkManager.request_vote(-1)
		else:
			NetworkManager.request_vote.rpc_id(1, -1)

func waiting_for_rematch():
	if NetworkManager.votes == 0:
		cancel_rematch()
		return
	
	if NetworkManager.has_voted:
		$Play_again_button.texture_normal = preload("res://assets/sprites/boton1-cancel.png")
		$Label.position.x = 386.0
		label_player.position.x = 1084.0
		
		if multiplayer.is_server():
			if NetworkManager.players.has(NetworkManager.client_id):
				var client_id = NetworkManager.client_id
				
				set_colour(client_id )
				$Label.text = "You voted to play again, waiting for"
				
				if !NetworkManager.players[client_id ].name == "":
					label_player.text = NetworkManager.players[client_id].name
				else:
					label_player.text = "Player 2"
		else:
			set_colour(1)
			$Label.text = "You voted to play again, waiting for"
			
			if !NetworkManager.players[1].name == "":
				label_player.text = NetworkManager.players[1].name
			else:
				label_player.text = "Player 1"
	else:
		if NetworkManager.votes == 1:
			label_player.position.x = 386.0
			
			if multiplayer.is_server():
				if NetworkManager.players.has(NetworkManager.client_id):
					var client_id = NetworkManager.client_id
					
					set_label_position(client_id)
					set_colour(client_id)
					$Label.text = "wants to play again. Accept?"
					
					if !NetworkManager.players[client_id].name == "":
						label_player.text = NetworkManager.players[client_id].name
					else:
						label_player.text = "Player 2"
					 
					$AnimationPlayer.play("rematch")
			else:
				set_label_position()
				set_colour()
				label_player.text = NetworkManager.players[1].name
				$Label.text = "wants to play again. Accept?"
				
				$AnimationPlayer.play("rematch")

func set_label_position(id := 1):
	var name
	var length
	var label = $Label
	
	if id == 1:
		name = NetworkManager.players[1].name
	else:
		name = NetworkManager.players[NetworkManager.client_id].name
	
	length = name.length()
	
	if length == 0:
		label.position.x = 568.0
	elif length == 1:
		label.position.x = 436.0
	elif length == 2:
		label.position.x = 457.0
	elif length == 3:
		label.position.x = 482.0
	elif length == 4:
		label.position.x = 504.0
	elif length == 5:
		label.position.x = 530.0
	elif length == 6:
		label.position.x = 554.0
	elif length == 7:
		label.position.x = 580.0

func cancel_rematch():
	$Play_again_button.texture_normal = preload("res://assets/sprites/boton1-play_again.png")
	$Label.text = ""
	label_player.text = ""

@rpc("authority", "call_local")
func start_rematch():
	$Label.position.x = 386.0
	label_player.text = ""
	$Play_again_button.disabled = true
	
	$Label.text = "Rematch starting in 3"
	await get_tree().create_timer(1.0).timeout
	$Label.text = "Rematch starting in 2"
	await get_tree().create_timer(1.0).timeout
	$Label.text = "Rematch starting in 1"
	await get_tree().create_timer(1.0).timeout
	
	if NetworkManager.players.size() == 2:
		NetworkManager.start_online_scored.rpc()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func update_votes(v):
	waiting_for_rematch()
	if v == 2 and multiplayer.is_server():
		start_rematch.rpc()

func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	$Click_sound.play()
	await button_press_animation($Exit_button)
	
	await get_tree().create_timer(0.1).timeout
	
	NetworkManager.reset_connections()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func player_disconnected(id):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	await notifications.player_disconnected_N(id)
	
	get_tree().paused = false
	NetworkManager.reset_connections()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func set_colour(id := 1):
	if !NetworkManager.players.has(id):
		return
	
	var colour = NetworkManager.players[id].skin
	
	if colour == "default":
		label_player.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	elif colour == "black":
		label_player.set("theme_override_colors/font_color", Color(0.0, 0.0, 0.0, 1.0))
	elif colour == "red":
		label_player.set("theme_override_colors/font_color", Color(1.0, 0.242, 0.219, 0.973))
	elif colour == "blue":
		label_player.set("theme_override_colors/font_color", Color(0.0, 1.0, 1.0, 1.0))
	elif colour == "green":
		label_player.set("theme_override_colors/font_color", Color(0.2, 0.961, 0.514, 1.0))
	elif colour == "pink":
		label_player.set("theme_override_colors/font_color", Color(0.858, 0.001, 0.866, 1.0))
	else:
		label_player.set("theme_override_colors/font_color", Color(1.0, 1.0, 0.227, 1.0))

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
