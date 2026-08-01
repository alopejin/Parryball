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
	freeze = false
	linear_velocity = Vector2.ZERO
	await get_tree().create_timer(0.1).timeout
	hit(Vector2.UP, 15000)
	sync_served.rpc(true)
	
func spawn(position: Vector2):
	global_position = position

func _on_body_entered(body: Node) -> void:
	$Hit_sound.play()

@rpc("any_peer", "call_local")
func request_serve(id):
	print("Player tring to serve " + str(id))
	
	if get_parent().name == "LAN_jam":
		if (id == 1 and LANNetworkManager.player1_serves) or (id != 1 and !LANNetworkManager.player1_serves):
			serve()
	
	elif get_parent().name == "Online_jam":
		if (id == 1 and NetworkManager.player1_serves) or (id != 1 and !NetworkManager.player1_serves):
			serve()
	
	elif get_parent().name == "LAN_scored":
		if (id == 1 and LANNetworkManager.player1_serves) or (id != 1 and !LANNetworkManager.player1_serves):
			serve()
	
	elif get_parent().name == "Online_scored":
		if (id == 1 and NetworkManager.player1_serves) or (id != 1 and !NetworkManager.player1_serves):
			serve()

@rpc("authority", "call_local")
func sync_served(value):
	served = value
