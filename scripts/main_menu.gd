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
		
func setup_button_sounds():
	var buttons = [play_button, options_button, exit_button]
	if back_button:
		buttons.append(back_button)
		
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover)
			button.pressed.connect(_on_button_click)
			
func _on_button_hover():
	if hover_sound and hover_sound.stream:
		hover_sound.pitch_scale = randf_range(0.95, 1.05)
		hover_sound.play()

func _on_button_click():
	# Suono click
	if hover_sound and hover_sound.stream:
		hover_sound.pitch_scale = 0.8
		hover_sound.play()

func _on_play_pressed():
	print("Starting game..")
	
	# Fade out Audio
	if music_player:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40.0, 0.5)
	
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
	print("Options button clicked")
	print("options_menu exists: ", options_menu != null)
	print("main_container exists: ", main_container != null)
	
	if options_menu == null:
		print("not found")
		return
		
	main_container.visible = false
	options_menu.visible = true
	
	if back_button:
		back_button.grab_focus()
		
func _on_exit_pressed():
	print("Exting..")
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().quit()
	)
	
# Options

func _on_back_pressed():
	close_options()
	
func close_options():
	if options_menu:
		options_menu.visible = false
	main_container.visible = true
	play_button.grab_focus()
	save_settings()
	
func _on_sensitivity_changed(value: float):
	print("Sensitivity: ", value)
	
func _on_volume_changed(value: float):
	var db = lerp(-60.0, 0.0, value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	print("Volume: ", value, "%")
	
func _on_fullscreen_toggled(enabled: bool):
	call_deferred("_apply_fullscreen", enabled)

func _apply_fullscreen(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	print("Fullscreen: ", enabled)
	
# Salva/Carica
func save_settings():
	var config = ConfigFile.new()
	if sensitivity_slider:
		config.set_value("controls", "sensitivity", sensitivity_slider.value)
	if volume_slider:
		config.set_value("audio", "volume", volume_slider.value)
	if fullscreen_check:
		config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.save("user://settings.cfg")
	print("Settings saved!")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		if sensitivity_slider:
			sensitivity_slider.value = config.get_value("controls", "sensitivity", 0.003)
		if volume_slider:
			volume_slider.value = config.get_value("audio", "volume", 100)
		if fullscreen_check:
			fullscreen_check.button_pressed = config.get_value("video", "fullscreen", false)
			if fullscreen_check.button_pressed:
				_apply_fullscreen(true)
	print("Settings saved!")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			
# Style
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
	
