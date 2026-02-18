extends Node2D


@onready var ball = preload("res://scenes/ball.tscn")

var score1 = 0
var score2 = 0
var player1_serves = true
var active_ball
var game_active = false

var player1: CharacterBody2D
var player2: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)

	if multiplayer.is_server():
		spawn_player(1)

func start_game():
	active_ball = ball.instantiate()
	add_child(active_ball)
	if randf() > 0.5:
		active_ball.spawn(player2.global_position + Vector2(0, 50))
		player1_serves = false
	else:
		active_ball.spawn(player1.global_position + Vector2(0, 50))
		
	game_active = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_active:
		if multiplayer.is_server():
			return
		if !active_ball.served:
			if player1_serves:
				active_ball.global_position = player1.global_position
			else:
				active_ball.global_position = player2.global_position

func _on_score_counter_body_entered(body: RigidBody2D) -> void:
	if body.is_in_group("ball"):
		print("aa")
		active_ball.served = false
		
		if body.global_position.x < $Net/Sprite2D.global_position.x:
			score2 += 1
			show_score()
			active_ball = ball.instantiate()
			add_child(active_ball)
			active_ball.spawn(player2.global_position + Vector2(0, 50))
			player1_serves = false
		else:
			score1 += 1
			show_score()
			active_ball = ball.instantiate()
			add_child(active_ball)
			print(active_ball.global_position)
			active_ball.spawn(player1.global_position + Vector2(0, 50))
			player1_serves = true
		
		body.queue_free()
		print(player1.global_position)


func show_score():
	$Score_P1.text = str(score1)
	$Score_P2.text = str(score2)

func _on_peer_connected(id: int = 1):
	var player_scene = load("res://scenes/player-online.tscn")
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player, true)
	if id == 1:
		player.global_position = Vector2(562, 903)
	else:
		player.global_position = Vector2(1373, 903)
	
	if multiplayer.get_peers().size() == 1:
		player.get_parent().player1 = player
		player.global_position = Vector2(562, 903)
	else:
		player.get_parent().player2 = player
		player.global_position = Vector2(1373, 903)
		player.get_parent().start_game()
	
	print("joder")

func spawn_player(id):
	pass
	var player_scene = load("res://scenes/player-online.tscn")
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player, true)
	if id == 1:
		player1 = player
		player.global_position = Vector2(562, 903)
	else:
		player2 = player
		player.global_position = Vector2(1373, 903)
	
	if player1 and player2:
		start_game()
