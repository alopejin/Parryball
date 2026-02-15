extends RigidBody2D


var served = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#global_position = get_parent().get_node("Player/BallSpawn").global_position
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !served:
		if get_parent().name == "Local_multiplayer":
			if get_parent().player1_serves:
				global_position = get_parent().get_node("Player/BallSpawn").global_position
			else:
				global_position = get_parent().get_node("Player2/BallSpawn").global_position
		else:
			global_position = get_parent().get_node("Player/BallSpawn").global_position
		

func hit(direction: Vector2, force: float):
	linear_velocity = Vector2.ZERO
	apply_impulse(direction.normalized() * force)
	#apply_impulse(Vector2(300, 0), Vector2(0, 20))
	print("joder2")

func serve():
	served = true
	await get_tree().create_timer(0.1).timeout
	#global_position = get_parent().get_node("Player/BallSpawn").global_position
	hit(Vector2.UP, 15000)
	
func spawn(position: Vector2):
	global_position = position
