extends Control

@onready var play_button := $VBoxContainer/PlayButton
@onready var options_button := $VBoxContainer/OptionsButton
@onready var exit_button := $VBoxContainer/ExitButton

# Scena
@export var game_scene: PackedScene

func _ready():
	# Mostra il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Connetti i bottoni
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Focus sul primo bottone
	play_button.grab_focus()
	# Animazione Fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
func _on_play_pressed():
	print("Starting game..")
	
	# Fade out e carica il gioco
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if game_scene:
			get_tree().change_scene_to_packed(game_scene)
		else:
			get_tree().change_scene_to_file("res://scene/main.tscn")
	)

func _on_options_pressed():
	print("Options..")
	pass
	
func _on_exit_pressed():
	print("Exting..")
	get_tree().quit()
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
