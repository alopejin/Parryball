extends RigidBody2D


@onready var main_trail = $Main_trail
@onready var left_trail = $Left_trail_alt
@onready var right_trail = $Right_trail_alt

var served = false
var trail_active = false
var trail_fast = false
var trail_following = false
var trail_min_speed = 1500.0
var fading_out = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_trail.modulate.a = 0.0
	freeze = true
	main_trail.clear_points()
	#left_trail.clear_points()
	#right_trail.clear_points()
	
	if !Global.ball_trail_on:
		main_trail.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	freeze = !served
	
	if !Global.ball_trail_on:
		return
	
	trail_fast = linear_velocity.length() > trail_min_speed
	
	if trail_fast and !trail_following:
		trail_following = true
		fade_in()
	elif !trail_fast and trail_following and !fading_out:
		fade_out()
	
	if trail_following:
		main_trail.add_point(global_position)
		if main_trail.get_point_count() > 10:
			main_trail.remove_point(0)

func hit(direction: Vector2, force: float):
	linear_velocity = Vector2.ZERO
	apply_impulse(direction.normalized() * force)
	#apply_impulse(Vector2(300, 0), Vector2(0, 20))

func serve():
	served = true
	show_trail()
	await get_tree().create_timer(0.1).timeout
	hit(Vector2.UP, 15000)
	
func spawn(position: Vector2):
	global_position = position
	play_start_effect()

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

func fade_in():
	#main_trail.modulate.a = 0.0
	fading_out = false
	var tween = create_tween()
	tween.tween_property(main_trail, "modulate:a", 1.0, 0.3)

func fade_out():
	fading_out = true
	var tween = create_tween()
	tween.tween_property(main_trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(fade_out_finished)
	
func fade_out_finished():
	trail_following = false
	fading_out = false
	main_trail.clear_points()

func show_trail():
	main_trail.visible = true

func hide_trail():
	main_trail.visible = false

func play_start_effect():
	var tween = create_tween()
	var scale = $Sprite2D.scale
	
	$Sprite2D.scale = Vector2(0.001, 0.001)
	
	tween.tween_property($Sprite2D, "scale", scale, 0.2)
