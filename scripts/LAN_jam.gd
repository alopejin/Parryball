extends Node2D


@onready var ball = preload("res://scenes/ball_online.tscn")

var player1_serves
var active_ball
var game_active = false

var player1: CharacterBody2D
var player2: CharacterBody2D
var player_online = preload("res://scenes/player-online.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var index = 0
	
	#$MultiplayerSynchronizer.set_multiplayer_authority(str(multiplayer.get_unique_id()).to_int())
	
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
		
	start_game.rpc()
	#if multiplayer.is_server():
	#	start_game()
	#	print("Starting")

@rpc("any_peer")
func start_game():
	active_ball = ball.instantiate()
	add_child(active_ball)
	#active_ball.set_multiplayer_authority(multiplayer.get_unique_id())
	#if multiplayer.is_server():
		
		
	game_active = true
	decide_serve.rpc()

@rpc("any_peer")
func decide_serve():
	if randf() > 0.5:
		print("Deciding")
		active_ball.spawn(player2.global_position + Vector2(0, -50))
		LANNetworkManager.player1_serves = false
		#p2_serves.rpc()
	else:
		active_ball.spawn(player1.global_position + Vector2(0, -50))
		LANNetworkManager.player1_serves = true
		#p1_serves.rpc()
	
	if is_multiplayer_authority():
		sync_serve.rpc(LANNetworkManager.player1_serves)

@rpc("any_peer")
func sync_serve(value):
	LANNetworkManager.player1_serves = value


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if game_active and $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		#if !active_ball.served:
		#	if player1_serves:
		#		active_ball.global_position = player1.global_position
		#	else:
		#		active_ball.global_position = player2.global_position
		pass

@rpc("any_peer")
func p1_serves():
	LANNetworkManager.player1_serves = true

@rpc("any_peer")
func p2_serves():
	LANNetworkManager.player1_serves = false
