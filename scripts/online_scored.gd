extends Node2D


@onready var ball = preload("res://scenes/ball_online.tscn")
@onready var notifications = $Notifications
@onready var label_player = $Label_player
@onready var marker = $Sparks/Marker2D  

@onready var sparks = {
	"N":  $Sparks/SparkN,
	"S":  $Sparks/SparkS,
	"W":  $Sparks/SparkW,
	"E":  $Sparks/SparkE,
	"NW": $Sparks/SparkNW,
	"NE": $Sparks/SparkNE,
	"SW": $Sparks/SparkSW,
	"SE": $Sparks/SparkSE,
}

const SPARK_OFFSETS = {
	"N":  Vector2(0, -20),
	"S":  Vector2(0, 20),
	"W":  Vector2(-20, 0),
	"E":  Vector2(20, 0),
	"NW": Vector2(-15, -15),
	"NE": Vector2(15, -15),
	"SW": Vector2(-15, 15),
	"SE": Vector2(15, 15),
}

var player1: CharacterBody2D
var player2: CharacterBody2D
var player_online = preload("res://scenes/player-online.tscn")

var score1 = 0
var score2 = 0
var active_ball
var current_move_tween: Tween
var current_fade_tween: Tween

var playing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sparks.visible = false
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
	play_wall_effect.rpc(NetworkManager.player1_serves)
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
				active_ball.global_position = player1.global_position + Vector2(0, -50)
				#active_ball.spawn(player1.global_position + Vector2(0, -50))
			else:
				active_ball.global_position = player2.global_position + Vector2(0, -50)
				#active_ball.spawn(player2.global_position + Vector2(0, -50))

func _on_score_counter_body_entered(body: RigidBody2D) -> void:
	if !multiplayer.is_server():
		return
	if !body.is_in_group("ball"):
		return
	if body != active_ball:
		return
	
	marker.global_position = body.global_position
	play_point_effect.rpc(body.global_position)
	
	if body.global_position.x < $Net/Sprite2D.global_position.x:
		score2 += 1
		NetworkManager.player1_serves = false
	else:
		score1 += 1
		NetworkManager.player1_serves = true
	
	play_wall_effect.rpc(NetworkManager.player1_serves)
	play_score_animation.rpc(NetworkManager.player1_serves)
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

@rpc("authority", "call_local")
func play_score_animation(player1_scores: bool):
	if player1_scores:
		$Score_P1/AnimationPlayer.play("score")
	else:
		$Score_P2/AnimationPlayer.play("score")

@rpc("authority","call_local")
func play_point_effect(pos: Vector2):
	if !Global.point_effect_on:
		return
	
	marker.global_position = pos
	$Sparks.visible = true
	
	for dir_name in sparks:
		var spark = sparks[dir_name]
		var offset = SPARK_OFFSETS[dir_name]
		var direction = offset.normalized()

		spark.global_position = marker.global_position + offset
		spark.rotation = direction.angle()
		spark.modulate.a = 1.0
		spark.visible = true

		var target_position = spark.global_position + direction * 50

		var tween = create_tween()
		tween.tween_property(spark, "global_position", target_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.4)

@rpc("authority","call_local")
func play_wall_effect(p1_serves: bool):
	if current_move_tween:
		current_move_tween.kill()
	if current_fade_tween:
		current_fade_tween.kill()

	var spark = $Lateral_spark

	var start_pos
	var mid1
	var mid2
	var end_pos
	
	if p1_serves:
		start_pos = Vector2(10, 1070)
		mid1 = Vector2(10, 10)
		mid2 = Vector2(1910, 10)
		end_pos = Vector2(1910, 1070)
	else:
		start_pos = Vector2(1910, 1070)
		mid1 = Vector2(1910, 10)
		mid2 = Vector2(10, 10)
		end_pos = Vector2(10, 1070)
	
	spark.position = start_pos
	spark.modulate.a = 1.0
	
	current_move_tween = create_tween()
	current_move_tween.tween_property(spark, "position", mid1, 1.5)
	current_move_tween.tween_property(spark, "position", mid2, 3.0)
	current_move_tween.tween_property(spark, "position", end_pos, 1.5)

	current_fade_tween = create_tween()
	current_fade_tween.set_loops()
	current_fade_tween.tween_property(spark, "modulate:a", 0.0, 0.5)
	current_fade_tween.tween_property(spark, "modulate:a", 1.0, 0.5)

	current_move_tween.finished.connect(_on_wall_effect_finished)

func _on_wall_effect_finished():
	current_fade_tween.kill()
	play_wall_effect(NetworkManager.player1_serves)

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
	$Sparks.visible = false
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
		if is_inside_tree(): 
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func update_votes(v):
	waiting_for_rematch()
	if v == 2 and multiplayer.is_server():
		start_rematch.rpc()

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Exit_button)
	await $Click_sound.finished
	
	await get_tree().create_timer(0.1).timeout
	
	NetworkManager.reset_connections()
	
	if is_inside_tree(): 
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func player_disconnected(id):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await notifications.player_disconnected_N(id)
	NetworkManager.reset_connections()
	
	if is_inside_tree(): 
		get_tree().paused = false
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
