extends Node2D

@onready var notifications = $Notifications
@onready var ball = preload("res://scenes/ball_online.tscn")

var player1_serves
var active_ball
var game_active = false

var player1: CharacterBody2D
var player2: CharacterBody2D
var player_online = preload("res://scenes/player-online.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_disconnected.connect(player_disconnected)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
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
	
	if NetworkManager.players.size() == 2 and multiplayer.is_server():
		start_game()

func start_game():
	decide_serve()
	create_ball.rpc()
	print("Game on")
	
	game_active = true

func decide_serve():
	if randf() > 0.5:
		NetworkManager.player1_serves = false
	else:
		NetworkManager.player1_serves = true
	
	if is_multiplayer_authority():
		sync_serve.rpc(NetworkManager.player1_serves)

@rpc("authority")
func sync_serve(value):
	NetworkManager.player1_serves = value

@rpc("authority", "call_local")
func create_ball():
	var b = ball.instantiate()
	b.name = "Ball"
	add_child(b)
	active_ball = b
	
	if multiplayer.is_server():
		reset_ball()

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


func player_disconnected(id):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await notifications.player_disconnected_N(id)
	NetworkManager.reset_connections()
	
	if is_inside_tree(): 
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")
