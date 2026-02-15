extends Node2D


@onready var ball = preload("res://scenes/ball.tscn")
@onready var player1 = get_node("Player").get_node("BallSpawn")
@onready var player2 = get_node("Player2").get_node("BallSpawn")

var score1 = 0
var score2 = 0
var player1_serves = true
var active_ball

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_ball = ball.instantiate()
	add_child(active_ball)
	if randf() > 0.5:
		active_ball.spawn(player2.global_position)
		player1_serves = false
	else:
		active_ball.spawn(player1.global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	show_score()
	if !active_ball.served:
		if player1_serves:
			active_ball.global_position = player1.global_position

func _on_score_counter_body_entered(body: RigidBody2D) -> void:
	if body.is_in_group("ball"):
		print("aa")
		active_ball.served = false
		
		if body.global_position.x < $Net/Sprite2D.global_position.x:
			score2 += 1
			active_ball = ball.instantiate()
			add_child(active_ball)
			active_ball.spawn(player2.global_position + Vector2(0, 50))
			player1_serves = false
		else:
			score1 += 1
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
