extends Node2D


@onready var ball = preload("res://scenes/ball.tscn")
@onready var player1 = get_node("Player").get_node("BallSpawn")
@onready var player2 = get_node("Player2").get_node("BallSpawn")
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

var score1 = 0
var score2 = 0
var player1_serves = true
var active_ball
var current_move_tween: Tween
var current_fade_tween: Tween

var playing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sparks.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Pause.process_mode = Node.PROCESS_MODE_ALWAYS
	disable_buttons()
	start_game()
	play_wall_effect()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	show_score()
	if !active_ball.served:
		if player1_serves:
			active_ball.global_position = player1.global_position
		else:
			active_ball.global_position = player2.global_position

func _on_score_counter_body_entered(body: RigidBody2D) -> void:
	if body.is_in_group("ball"):
		active_ball.served = false
		$Score_sound.play()
		
		marker.global_position = body.global_position
		play_point_effect()
		
		if body.global_position.x < $Net/Sprite2D.global_position.x:
			score2 += 1
			$Score_P2/AnimationPlayer.play("score")
			player1_serves = false
		else:
			score1 += 1
			$Score_P1/AnimationPlayer.play("score")
			player1_serves = true
		
		
		play_wall_effect()
		reset_ball()
		check_victory()

func play_point_effect():
	if !Global.point_effect_on:
		return
	
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

func play_wall_effect():
	if current_move_tween:
		current_move_tween.kill()
	if current_fade_tween:
		current_fade_tween.kill()

	var spark = $Lateral_spark

	var start_pos
	var mid1
	var mid2
	var end_pos
	
	if player1_serves:
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
	play_wall_effect()

func decide_serve():
	if randf() > 0.5:
		player1_serves = false
	else:
		player1_serves = true

func start_game():
	decide_serve()
	create_ball()

func create_ball():
	var b = ball.instantiate()
	b.name = "Ball"
	add_child(b)
	active_ball = b
	reset_ball()

func reset_ball():
	active_ball.linear_velocity = Vector2.ZERO
	active_ball.angular_velocity = 0.0
	
	if player1_serves:
		active_ball.spawn(player1.global_position + Vector2(0, -50))
	else:
		active_ball.spawn(player2.global_position + Vector2(0, -50))

func show_score():
	$Score_P1.text = str(score1)
	$Score_P2.text = str(score2)

func check_victory():
	if score1 == 10 or score2 == 10:
		if score1 == 10:
			if !Global.local_player1_name == "":
				$Winner_label.text = Global.local_player1_name + " wins !"
			else:
				$Winner_label.text = "Player 1 wins !"
		else:
			if !Global.local_player2_name == "":
				$Winner_label.text = Global.local_player2_name + " wins !"
			else:
				$Winner_label.text = "Player 2 wins !"
		
		$Pause.process_mode = Node.PROCESS_MODE_DISABLED
		$Victory_sound.play()
		active_ball.hide_trail()
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
	await $Click_sound.finished
	
	if is_inside_tree():
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	$Click_sound.play()
	await button_press_animation($Exit_button)
	await $Click_sound.finished
	
	if is_inside_tree(): 
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
