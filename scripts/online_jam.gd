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
	#if NetworkManager.players.size() == 2:
	start_game.rpc()

@rpc("any_peer")
func start_game():
	active_ball = ball.instantiate()
	add_child(active_ball)
	if multiplayer.is_server():
		print("Game on")
		if randf() > 0.5:
			active_ball.spawn(player2.global_position + Vector2(0, -50))
			NetworkManager.player1_serves = false
		else:
			active_ball.spawn(player1.global_position + Vector2(0, -50))
			NetworkManager.player1_serves = true
		
	game_active = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if game_active and $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		#if !active_ball.served:
		#	if player1_serves:
		#		active_ball.global_position = player1.global_position
		#	else:
		#		active_ball.global_position = player2.global_position
		pass
