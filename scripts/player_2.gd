extends CharacterBody2D


@onready var ball = get_parent().get_node("Ball")

const SPEED = 600.0
const JUMP_VELOCITY = -1200.0

var parry_on = false

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
			if ball and !ball.served:
				ball.serve()
		else:
			if !get_parent().get_node("Ball").served:
				get_parent().get_node("Ball").serve()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Ball":
		var dir = transform.x.normalized()
		ball.hit(dir, 15000)
