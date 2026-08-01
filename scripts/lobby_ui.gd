extends Node


@onready var label_host = $CanvasLayer/Label_host
@onready var label_client = $CanvasLayer/Label_client

func _ready() -> void:
	reset_ui()

func show_ui():
	$CanvasLayer.visible = true

func hide_ui():
	$CanvasLayer.visible = false

func update_ui(id):
	if id == -1:
		reset_ui()
		return
	
	if id == 1:
		if NetworkManager.players.has(id):
			set_colour(id)
			if !NetworkManager.players[id].name == "":
				label_host.text = NetworkManager.players[id].name + " - Host"
			else:
				label_host.text = "Player 1 - Host"
			
		if NetworkManager.players.size() == 1:
			label_client.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
			label_client.text = "*Free spot*"
	else:
		if NetworkManager.players.has(1):
			set_colour(1)
			if !NetworkManager.players[1].name == "":
				label_host.text = NetworkManager.players[1].name + " - Host"
			else:
				label_host.text = "Player 1 - Host"
		
		if NetworkManager.players.has(id):
			set_colour(id)
			if NetworkManager.players[id].name == "":
				label_client.text = "Player 2"
			else:
				label_client.text = NetworkManager.players[id].name
	
	show_ui()

func reset_ui():
	hide_ui()
	label_host.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	label_client.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	label_host.text = ""
	label_client.text = ""

func set_colour(id := 1):
	if !NetworkManager.players.has(id):
		return
	
	var label
	var colour = NetworkManager.players[id].skin
	
	if id == 1:
		label = label_host
	else:
		label = label_client
	
	if colour == "default":
		label.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	elif colour == "black":
		label.set("theme_override_colors/font_color", Color(0.0, 0.0, 0.0, 1.0))
	elif colour == "red":
		label.set("theme_override_colors/font_color", Color(1.0, 0.242, 0.219, 0.973))
	elif colour == "blue":
		label.set("theme_override_colors/font_color", Color(0.0, 1.0, 1.0, 1.0))
	elif colour == "green":
		label.set("theme_override_colors/font_color", Color(0.2, 0.961, 0.514, 1.0))
	elif colour == "pink":
		label.set("theme_override_colors/font_color", Color(0.858, 0.001, 0.866, 1.0))
	else:
		label.set("theme_override_colors/font_color", Color(1.0, 1.0, 0.227, 1.0))
