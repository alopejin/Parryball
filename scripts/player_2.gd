extends CharacterBody2D


const SPEED = 700.0
const JUMP_VELOCITY = -1200.0

var parry_on = false

func _ready() -> void:
	$Skins.play(Global.local_player2_skin[Global.index_player2])
	$Name.text = Global.local_player2_name
	play_breathing_glow()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump-p2") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("jump-p2") and velocity.y < 0:
		await get_tree().create_timer(0.1).timeout
		velocity.y *= 0

	var direction := Input.get_axis("left-p2", "right-p2")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if Input.is_action_just_pressed("parry-p2") and !is_on_floor():
		parry_on = true
		$AnimationPlayer.play("parry_reverse")
		await $AnimationPlayer.animation_finished
		parry_on = false

	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("serve-p2"):
		if get_parent().name == "Local_multiplayer":
			var ball = get_parent().active_ball
			if ball and !ball.served and !get_parent().player1_serves:
				ball.serve()
		else:
			if !get_parent().get_node("Ball").served:
				get_parent().get_node("Ball").serve()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if !Global.easy_hit_on:
		return
	
	if body.name == "Ball" and parry_on:
		var facing 
		var angle_rad = deg_to_rad(35)
		
		if global_position.x > get_parent().get_node("Net/Sprite2D").global_position.x:
			facing = -1
		else:
			facing = 1
		
		var dir = Vector2(cos(angle_rad) * facing, -sin(angle_rad)).normalized()
		var force = 10000 + int(velocity.length()) * 10
		var ball
		
		if !get_parent().name == "Local_jam":
			ball = get_parent().active_ball
		else:
			ball = get_parent().get_node("Ball")
		
		ball.hit(dir, force)

func play_breathing_glow():
	$Glow.modulate.a = 0.0

	var tween = create_tween()
	
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Glow, "modulate:a", 0.1, 0.4)
	tween.tween_property($Glow, "modulate:a", 0.0, 0.4)
