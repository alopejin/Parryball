extends CharacterBody2D


const ACCELERATION = 50

var speed = 300
var direction : Vector2

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var collision = move_and_collide(direction * speed * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.name == "Border":
			speed += ACCELERATION
		
		direction = direction.bounce(collision.get_normal())
		
	move_and_slide()
		
