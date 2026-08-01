extends RigidBody2D


var served = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freeze = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	freeze = !served

func hit(direction: Vector2, force: float):
	linear_velocity = Vector2.ZERO
	apply_impulse(direction.normalized() * force)
	#apply_impulse(Vector2(300, 0), Vector2(0, 20))

func serve():
	served = true
	await get_tree().create_timer(0.1).timeout
	hit(Vector2.UP, 15000)
	
func spawn(position: Vector2):
	global_position = position

func _on_body_entered(body: Node) -> void:
	$Hit_sound.play()
	if body.is_in_group("ball"):
		hit(Vector2.ZERO, 10000)

@rpc("any_peer","call_local")
func request_serve(id):
	if !is_multiplayer_authority() or served:
		return
		
	if !served:
		served = true
		apply_impulse(Vector2.UP * 150000)
		print("Ball served")

func _enter_tree():
	set_multiplayer_authority(1) 
	
