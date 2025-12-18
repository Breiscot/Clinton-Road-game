extends Control

@onready var resume_button := $VBoxContainer/ResumeButton
@onready var options_button := $VBoxContainer/OptionsButton
@onready var main_menu_button := $VBoxContainer/MainMenuButton
@onready var quit_button := $VBoxContainer/QuitButton
@onready var main_container := $VBoxContainer

@onready var options_menu := $OptionsMenu
@onready var sensitivity_slider := $OptionsMenu/VBoxContainer/SensitivityContainer/SensitivitySlider
@onready var volume_slider := $OptionsMenu/VBoxContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_check := $OptionsMenu/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var back_button := $OptionsMenu/VBoxContainer/BackButton

var is_paused := false
var player: CharacterBody3D = null

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Funziona in pausa
	
	# Nascondi OptionsMenu
	if options_menu:
		options_menu.visible = false
	
	# Button connessi menu principale
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connetti controlli options
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		
	await get_tree().physics_frame
	find_player()
	
	load_settings()
	
	style_buttons()
	
func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if options_menu and options_menu.visible:
			close_options()
		else:
			toggle_pause()
			
func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		pause_game()
	else:
		resume_game()
		
func pause_game():
	is_paused = true
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.grab_focus()
	
	# Animazione Fade In
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
func resume_game():
	is_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Animazione in Fade Out
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	
# Menu principale
	
func _on_resume_pressed():
	resume_game()
	
func _on_options_pressed():
	if options_menu:
		options_menu.visible = true
		$VBoxContainer.visible = false
		
func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
	
# Menu Options

func _on_back_pressed():
	close_options()
	
func close_options():
	if options_menu:
		options_menu.visible = false
	main_container.visible = true
	resume_button.grab_focus()
	save_settings()
	
func _on_sensitivity_changed(value: float):
	if player and "mouse_sensitivity" in player:
		player.mouse_sensitivity = value
	print("Sensitivity: ", value)
	
func _on_volume_changed(value: float):
	var db = lerp(-60.0, 0.0, value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	print("Volume: ", value, "%(",db," dB)")
	
func _apply_fullscreen(enabled: bool):
	call_deferred("_apply_fullscreen", enabled)
	print("Fullscreen: ", enabled)
	
func _on_fullscreen_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# Deve coprire tutto lo schermo
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		var screen_size = DisplayServer.screen_get_size()
		var window_size = Vector2i(1200, 720)
		DisplayServer.window_set_size(window_size)
		var pos = (screen_size - window_size) / 2
		DisplayServer.window_set_position(pos)
		
	print("Fullscreen: ", enabled)
	
# Salva/Carica Options

func save_settings():
	var config = ConfigFile.new()
	config.set_value("controls", "sensitivity", sensitivity_slider.value if sensitivity_slider else 0.003)
	config.set_value("audio", "volume", volume_slider.value if volume_slider else 100)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed if fullscreen_check else false)
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
			
		_on_sensitivity_changed(sensitivity_slider.value if sensitivity_slider else 0.003)
		_on_volume_changed(volume_slider.value if volume_slider else 100)
		_on_fullscreen_toggled(fullscreen_check.button_pressed if fullscreen_check else false)
		print("Settings loaded!")
	else:
		print("No settings file, using defaults")

# Style
	
func style_buttons():
	var buttons = [resume_button, options_button, main_menu_button, quit_button]
	
	for button in buttons:
		# Stile Normale
		var normal_style:= StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		normal_style.border_color = Color(0.4, 0.4, 0.5)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(5) 
		button.add_theme_stylebox_override("normal", normal_style)
		
		# Stile Hover
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.25, 0.35, 0.9)
		hover_style.border_color = Color(0.6, 0.6, 0.7)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("hover", hover_style)
		
		# Colore testo
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		button.add_theme_font_size_override("font_size", 20)
	
