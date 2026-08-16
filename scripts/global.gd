extends Node


signal window_set

var ball_trail_on = true
var point_effect_on = true
var setting_key = false

var index = 0
var index_player2 = 0

var local_player1_name : String = ""
var local_player1_skin = ["default", "black", "red", "blue", "green", "pink", "yellow"]

var local_player2_name : String = ""
var local_player2_skin = ["default", "black", "red", "blue", "green", "pink", "yellow"]

func _ready() -> void:
	get_window().set_mode(Window.MODE_FULLSCREEN)
	window_set.emit()
