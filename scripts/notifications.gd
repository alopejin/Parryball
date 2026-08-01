extends Node


@onready var label1 = $CanvasLayer/Background/Label_status
@onready var animation = $CanvasLayer/Notification_animation

var playing = false

func _ready() -> void:
	hide_panel()

func connection_attempt_N():
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	show_panel()
	
	label1.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	label1.text = "                Connecting"
	animation.play("fade-in")
	await animation.animation_finished
	
	while NetworkManager.connecting:
		if !is_inside_tree():
			return
		
		await get_tree().create_timer(0.4).timeout
		label1.text = "                Connecting"
		await get_tree().create_timer(0.4).timeout
		label1.text = "                Connecting."
		await get_tree().create_timer(0.4).timeout
		label1.text = "                Connecting.."
		await get_tree().create_timer(0.4).timeout
		label1.text = "                Connecting..."
	
	animation.play("fade-out")
	await animation.animation_finished
	
	hide_panel()
	label1.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	
	playing = false

func connection_success_N():
	var text = "Connection successful!"
	standard_notification(text)

func connection_failed_N():
	var text = "Connection failed :("
	standard_notification(text)

func player_connected_N(id):
	while !NetworkManager.players.has(id):
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	var text
	
	if id == 1:
		if !NetworkManager.players[id].name == "":
			text = " You joined " + NetworkManager.players[id].name + "!"
		else:
			text = " You joined Player 1!"
	else:
		if !NetworkManager.players[id].name == "":
			text = NetworkManager.players[id].name + " has joined!"
		else:
			text = "Player 2 has joined!"
	
	standard_notification(text)

func player_disconnected_N(id):
	var text
	
	if id == 1:
		if !NetworkManager.players[id].name == "":
			text = NetworkManager.players[id].name + " has disconected"
		else:
			text = "Player 1 has disconected"
	else:
		if !NetworkManager.players[id].name == "":
			text = NetworkManager.players[id].name + " has disconected"
		else:
			text = "Player 2 has disconected"
	
	await standard_notification(text)

func hosting_N():
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	show_panel()
	
	label1.text = "Hosting"
	animation.play("hosting")
	await animation.animation_finished
	label1.text = ""
	
	hide_panel()
	
	playing = false

func connection_join_error_N():
	var text = "You can't join your own OID"
	standard_notification(text)

func noray_restarted_N(time := 1):
	var text = "Noray OID updated"
	standard_notification(text, time)

func server_down_N():
	var text = "Server is down, try the other one"
	standard_notification(text)

func standard_notification(text := "", time := 1.0):
	while playing:
		if !is_inside_tree():
			return
		await get_tree().process_frame
	
	playing = true
	
	show_panel()
	
	label1.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label1.text = text
	
	animation.play("fade-in")
	await animation.animation_finished
	await get_tree().create_timer(time).timeout
	animation.play("fade-out")
	await animation.animation_finished
	
	hide_panel()
	
	playing = false

func show_panel():
	$CanvasLayer/Background.visible = true

func hide_panel():
	$CanvasLayer/Background.visible = false
