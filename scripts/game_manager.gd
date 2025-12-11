extends Node

var player: CharacterBody3D
var is_game_over := false

func _ready():
	player = get_tree().get_first_node_in_group("player")

	# Connetti segnali
	EventBus.connect("player_died", _on_player_died)

	print("Game started")
	print("Controls:")
	print("WASD - Move")
	print("Mouse - Look around")
	print("Shift - Run")
	print("Ctrl - Crouch")
	print("Space - Jump")
	print("F: - Flashlight")
	print("Esc - Pause Menu")

func _on_player_died():
	is_game_over = true
	print("You Died")

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _process(delta):
	# Restart con R
	if Input.is_action_just_pressed("ui_text_submit"): # Enter
		get_tree().reload_current_scene()
