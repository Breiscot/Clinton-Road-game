extends Control
# Menu
@onready var play_button := $VBoxContainer/PlayButton
@onready var options_button := $VBoxContainer/OptionsButton
@onready var exit_button := $VBoxContainer/ExitButton
@onready var main_container := $VBoxContainer

# Options
@onready var options_menu := $OptionsMenu
@onready var sensitivity_slider := $OptionsMenu/VBoxContainer/SensitivityContainer/SensitivitySlider
@onready var volume_slider := $OptionsMenu/VBoxContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_check := $OptionsMenu/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var back_button := $OptionsMenu/VBoxContainer/BackButton

# Audio
@onready var music_player := $AudioManager/MusicPlayer
@onready var ambience_player := $AudioManager/AmbientPlayer
@onready var hover_sound := $AudioManager/HoverSound

# Scena
@export var game_scene: PackedScene

func _ready():
	# Mostra il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Nascondi l'options menu all'inizio
	if options_menu:
		options_menu.visible = false
	
	# Connetti i bottoni
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Connetti HoverSound ai Button
	setup_button_sounds()
	
	# Connetti Controlli Options
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Carica Options
	load_settings()
	
	# Focus sul primo bottone
	play_button.grab_focus()
	
	# Style nei Button
	style_buttons()
	
	# Avvia Audio
	start_audio()
	
	# Animazione Fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
# Audio
func start_audio():
	# Avvia musica in Fade In
	if music_player and music_player.stream:
		music_player.volume_db = -40
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -10.0, 2.0)
	
	# Avvia ambiente
	if ambience_player and ambience_player.stream:
		ambience_player.volume_db = -40
		ambience_player.play()
		var tween = create_tween()
		tween.tween_property(ambience_player, "volume_db", -15.0, 2.0)
	
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
