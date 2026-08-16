extends CharacterBody2D


const SPEED = 600.0
const JUMP_VELOCITY = -1200.0

var parry_on = false

func _ready() -> void:
	$Skins.play(Global.local_player1_skin[Global.index])
	$Name.text = Global.local_player1_name

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump-p1") and is_on_floor():
		velocity.y = JUMP_VELOCITY
			
	if Input.is_action_just_released("jump-p1") and velocity.y < 0:
		await get_tree().create_timer(0.1).timeout
		velocity.y *= 0

	var direction := Input.get_axis("left-p1", "right-p1")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_just_pressed("parry-p1") and !is_on_floor():
		parry_on = true
			
		if global_position.x > get_parent().get_node("Net/Sprite2D").global_position.x:
			$AnimationPlayer.play("parry_reverse")
		else:
			$AnimationPlayer.play("parry")
			
		await $AnimationPlayer.animation_finished
		parry_on = false

	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("serve-p1"):
		if get_parent().name == "Local_multiplayer":
			var ball = get_parent().active_ball
			if ball and !ball.served and get_parent().player1_serves:
				ball.serve()
		else:
			if !get_parent().get_node("Ball").served:
				get_parent().get_node("Ball").serve()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Ball" and parry_on:
		var dir = transform.x.normalized()
		var ball = get_parent().active_ball
		ball.hit(dir, 20000)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
