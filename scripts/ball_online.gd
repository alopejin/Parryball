extends RigidBody2D


var served = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#global_position = get_parent().get_node("Player/BallSpawn").global_position
	pass
	freeze = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#if !served:
	#	if get_parent().name == "Local_multiplayer":
	#		if get_parent().player1_serves:
	#			global_position = get_parent().get_node("Player/BallSpawn").global_position
	#		else:
	#			global_position = get_parent().get_node("Player2/BallSpawn").global_position
	#	else:
	#		global_position = get_parent().get_node("Player/BallSpawn").global_position
	#if !is_multiplayer_authority():
	#	return
	
	#freeze = !served
	
	pass
	
	#if !served:
	#	freeze = true
	#else:
	#	freeze = false

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

func _on_body_entered(body: Node) -> void:
	$Hit_sound.play()

#@rpc("authority")
@rpc("any_peer", "call_local")
func request_serve(id):
	print("Player tring to serve " + str(id))
	print(str(LANNetworkManager.player1_serves))
	#if !is_multiplayer_authority() or served:
	#	return
	if get_parent().name == "LAN_jam":
		if (id == 1 and LANNetworkManager.player1_serves) or (id != 1 and !LANNetworkManager.player1_serves):
			#freeze = false
			print("Condition")
			print(str(served))
			#if !served:
				#freeze = false
			served = true
			freeze = false
			linear_velocity = Vector2.ZERO
			apply_impulse(Vector2.UP.normalized() * 15000)
		
	elif get_parent().name == "Online_jam":
		if (id == 1 and NetworkManager.player1_serves) or (id != 1 and !NetworkManager.player1_serves):
			#freeze = false
			print("Condition")
			print(str(served))
			#if !served:
				#freeze = false
			served = true
			freeze = false
			linear_velocity = Vector2.ZERO
			apply_impulse(Vector2.UP.normalized() * 15000)


func _enter_tree():
	#set_multiplayer_authority(1) 
	pass
	
	
