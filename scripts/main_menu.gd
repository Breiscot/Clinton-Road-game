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
	
	# Style nei Button
	style_buttons()
	
func style_buttons():
	var buttons = [play_button, options_button, exit_button]
	
	for button in buttons:
		# Stile normale
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
		normal_style.border_color = Color(0.3, 0.0, 0.0)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", normal_style)
		
		# Stile hover
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.0, 0.0, 0.9)
		hover_style.border_color = Color(0.6, 0.0, 0.0)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("hover", hover_style)
		
		# Stile pressed
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.4, 0.0, 0.0, 0.9)
		pressed_style.border_color = Color(0.8, 0.0, 0.0)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("pressed", pressed_style)
		
		# Colore testo
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		button.add_theme_color_override("font_hover_color", Color(1, 0.3, 0.3))
		button.add_theme_font_size_override("font_size", 24)
	
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
