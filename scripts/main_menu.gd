extends Node3D

# Camera
@onready var menu_camera: Camera3D = $MenuCamera

# UI Containers
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var main_menu_ui: Control = $CanvasLayer/MainMenuUI
@onready var options_menu: Control = $CanvasLayer/OptionsMenu
@onready var chapter_select_menu: Control = $CanvasLayer/ChapterSelectMenu

# Main Menu Elements
@onready var left_container: VBoxContainer = $CanvasLayer/MainMenuUI/LeftContainer
@onready var title_label: Label = $CanvasLayer/MainMenuUI/LeftContainer/Title
@onready var play_button: Button = $CanvasLayer/MainMenuUI/LeftContainer/PlayButton
@onready var options_button: Button = $CanvasLayer/MainMenuUI/LeftContainer/OptionsButton
@onready var exit_button: Button = $CanvasLayer/MainMenuUI/LeftContainer/ExitButton
@onready var github_link: LinkButton = $CanvasLayer/GithubLink
@onready var version_label: Label = $CanvasLayer/Version

# Options Elements
@onready var sensitivity_slider: HSlider = $CanvasLayer/OptionsMenu/VBoxContainer/SensitivityContainer/SensitivitySlider
@onready var volume_slider: HSlider = $CanvasLayer/OptionsMenu/VBoxContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_check: CheckButton = $CanvasLayer/OptionsMenu/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var back_button: Button = $CanvasLayer/OptionsMenu/VBoxContainer/BackButton

# Chapter Select Elements
@onready var chapter_container: VBoxContainer = $CanvasLayer/ChapterSelectMenu/ChapterContainer
@onready var chapter1_button: Button = $CanvasLayer/ChapterSelectMenu/ChapterContainer/Chapter1Button
@onready var chapter2_button: Button = $CanvasLayer/ChapterSelectMenu/ChapterContainer/Chapter2Button
@onready var chapter3_button: Button = $CanvasLayer/ChapterSelectMenu/ChapterContainer/Chapter3Button
@onready var chapter_back_button: Button = $CanvasLayer/ChapterSelectMenu/ChapterContainer/BackButton

# Audio
@onready var music_player := $AudioManager/MusicPlayer
@onready var ambience_player := $AudioManager/AmbientPlayer
@onready var hover_sound := $AudioManager/HoverSound

# Camera positions
var camera_start_pos := Vector3(-2.284, 3.4, 4.733)
var camera_start_rot := Vector3(0, -20, 0)
var camera_end_pos := Vector3(0.5, 1.4, -6.7)
var camera_end_rot := Vector3(-5, 180, 0)

# Camera animation
var camera_move_duration := 2.0
var is_camera_moving := false

# Chapter scenes
var chapter_scenes := {
	1: "res://scene/main.tscn",
	2: "res://scene/new_area.tscn",
	3: "res://scene/sewers.tscn"
}

# Chapter names
var chapter_names := {
	1: "Chapter 1: Forest",
	2: "Chapter 2: Road",
	3: "Chapter 3: Sewers"
}

func _ready():
	# Mostra il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if menu_camera:
		menu_camera.position = camera_start_pos
		menu_camera.rotation_degrees = camera_start_rot
		menu_camera.current = true
	
	# Nascondi menu secondari
	if options_menu:
		options_menu.visible = false
	if chapter_select_menu:
		chapter_select_menu.visible = false
	
	# Connetti i bottoni del menu principale
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Connetti i bottoni dei capitoli
	if chapter1_button:
		chapter1_button.pressed.connect(_on_chapter1_pressed)
	if chapter2_button:
		chapter2_button.pressed.connect(_on_chapter2_pressed)
	if chapter3_button:
		chapter3_button.pressed.connect(_on_chapter3_pressed)
	if chapter_back_button:
		chapter_back_button.pressed.connect(_on_chapter_back_pressed)
	
	# Connetti Controlli Options
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		
	# Connetti HoverSound ai Button
	setup_button_sounds()
	
	# Carica Options
	load_settings()
	
	# Style nei Button
	style_buttons()
	
	# Focus sul primo bottone
	play_button.grab_focus()
	
	# Avvia Audio
	start_audio()
	
	# Fade in
	main_menu_ui.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.5)
	
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
	if chapter1_button:
		buttons.append(chapter1_button)
	if chapter2_button:
		buttons.append(chapter2_button)
	if chapter3_button:
		buttons.append(chapter3_button)
	if chapter_back_button:
		buttons.append(chapter_back_button)
		
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover)
			
func _on_button_hover():
	if hover_sound and hover_sound.stream:
		hover_sound.pitch_scale = randf_range(0.95, 1.05)
		hover_sound.play()
	
# Main Menu
func _on_play_pressed():
	if is_camera_moving:
		return
		
	print("Play pressed, moving camera...")
	is_camera_moving = true
	
	# Fade out Menu principale
	var fade_tween = create_tween()
	fade_tween.tween_property(main_menu_ui, "modulate:a", 0.0, 0.3)
	
	# Muovi la camera
	var camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_trans(Tween.TRANS_SINE)
	
	camera_tween.tween_property(menu_camera, "position", camera_end_pos, camera_move_duration)
	camera_tween.tween_property(menu_camera, "rotation_degrees", camera_end_rot, camera_move_duration)
	
	await camera_tween.finished
	
	# Nascondi menu principale
	main_menu_ui.visible = false
	
	# Mostra selezione capitoli
	show_chapter_select()
	
	is_camera_moving = false
	
func _on_options_pressed():
	print("Options pressed")
	main_menu_ui.visible = false
	options_menu.visible = true
	
	if back_button:
		back_button.grab_focus()
		
func _on_exit_pressed():
	print("Exting..")
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(canvas_layer, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().quit()
	)
	
# Chapter Select	
func show_chapter_select():
	# Aggiorna stato bottoni capitoli
	update_chapter_buttons()
	
	# Menu capitoli con Fade in
	chapter_select_menu.visible = true
	chapter_select_menu.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(chapter_select_menu, "modulate:a", 1.0, 0.3)
	
	if chapter1_button:
		chapter1_button.grab_focus()
	
func update_chapter_buttons():
	var progress = load_chapter_progress()
	
	# Capitolo 1
	if chapter1_button:
		chapter1_button.disabled = false
		chapter1_button.text = chapter_names[1]
		chapter1_button.modulate.a = 1.0
		
	# Capitolo 2
	if chapter2_button:
		var unlocked = progress.get("chapter_1_completed", false)
		chapter2_button.disabled = not unlocked
		if unlocked:
			chapter2_button.text = chapter_names[2]
		else:
			chapter2_button.text = chapter_names[2] + " [LOCKED]"
		chapter2_button.modulate.a = 1.0 if unlocked else 0.5
		
	# Capitolo 3
	if chapter3_button:
		var unlocked = progress.get("chapter_2_completed", false)
		chapter3_button.disabled = not unlocked
		if unlocked:
			chapter3_button.text = chapter_names[3]
		else:
			chapter3_button.text = chapter_names[3] + " [LOCKED]"
		chapter3_button.modulate.a = 1.0 if unlocked else 0.5
		
func _on_chapter1_pressed():
	start_chapter(1)

func _on_chapter2_pressed():
	start_chapter(2)

func _on_chapter3_pressed():
	start_chapter(3)
	
func _on_chapter_back_pressed():
	print("Back to main menu")
	
	# Fade out chapter select
	var fade_tween = create_tween()
	fade_tween.tween_property(chapter_select_menu, "modulate:a", 0.0, 0.3)
	
	await fade_tween.finished
	chapter_select_menu.visible = false
	
	# Muovi camera indietro
	is_camera_moving = true
	
	var camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_trans(Tween.TRANS_SINE)
	
	camera_tween.tween_property(menu_camera, "position", camera_start_pos, camera_move_duration)
	camera_tween.tween_property(menu_camera, "rotation_degrees", camera_start_rot, camera_move_duration)
	
	await camera_tween.finished
	
	main_menu_ui.visible = true
	main_menu_ui.modulate.a = 0.0
	
	var show_tween = create_tween()
	show_tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.3)
	
	play_button.grab_focus()
	is_camera_moving = false
	
func start_chapter(chapter_num: int):
	print("Starting chapter ", chapter_num)
	
	if not chapter_scenes.has(chapter_num):
		print("ERR. chapter scene not found")
		return
		
	# Carica la scena del capitolo
	var scene_path = chapter_scenes[chapter_num]
	print("Scene path: ", scene_path)
	
	if not FileAccess.file_exists(scene_path):
		print("ERR. Scene file does not exist: ", scene_path)
		return
		
	print("Scene file exists!")
	
	# Fade out Audio
	if music_player:
		var audio_tween = create_tween()
		audio_tween.tween_property(music_player, "volume_db", -40.0, 0.5)
	
	# Fade out schermo
	if chapter_select_menu:
		print("Fading out chapter select menu...")
		var fade_tween = create_tween()
		fade_tween.tween_property(canvas_layer, "modulate:a", 0.0, 0.5)
		await fade_tween.finished
	else:
		print("WARNING: chapter_select_menu is null")

	# Carica la schermata di caricamento
	var loading_scene = load("res://scene/ui/loading_screen.tscn")
	
	if loading_scene:
		var loading_screen = loading_scene.instantiate()
		get_tree().root.add_child(loading_screen)
		
		if loading_screen.has_method("load_scene"):
			print("calling load_scene with path: ", scene_path)
			queue_free()
			loading_screen.load_scene(scene_path)
		else:
			loading_screen.queue_free()
			get_tree().change_scene_to_file(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
		
# Progress SAVE/LOAD
func load_chapter_progress() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load("user://progress.cfg")
	
	if err != OK:
		return {
			"chapter_1_completed": false,
			"chapter_2_completed": false,
			"chapter_3_completed": false
		}
		
	return {
		"chapter_1_completed": config.get_value("progress", "chapter_1_completed", false),
		"chapter_2_completed": config.get_value("progress", "chapter_2_completed", false),
		"chapter_3_completed": config.get_value("progress", "chapter_3_completed", false)
	}
	
static func save_chapter_completed(chapter_num: int):
	var config = ConfigFile.new()
	config.load("user://progress.cfg") # Carica esistente se esiste
	
	config.set_value("progress", "chapter_" + str(chapter_num) + "_completed", true)
	config.save("user://progress.cfg")
	
	print("Chapter ", chapter_num, " marked as completed!")
	
func load_game_scene(loading_screen: Control):
	var progress_bar = loading_screen.get_node("VBoxContainer/ProgressBar") as ProgressBar
	var scene_path := "res://scene/main.tscn"
	
	var error = ResourceLoader.load_threaded_request(scene_path)

	if error != OK:
		loading_screen.queue_free()
		get_tree().change_scene_to_file(scene_path)
		return
		
	var load_progress := []
	var scene_load_status := 0
	
	while true:
		scene_load_status = ResourceLoader.load_threaded_get_status(scene_path, load_progress)
		
		if load_progress.size() > 0 and progress_bar:
			progress_bar.value = load_progress[0] * 100
			
		match scene_load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
				
			ResourceLoader.THREAD_LOAD_LOADED:
				if progress_bar:
					progress_bar.value = 100
				# Aspetta un attimo	
				await  get_tree().create_timer(0.3).timeout
				# Scena caricata
				var loaded_scene = ResourceLoader.load_threaded_get(scene_path)
				# Rimuovi loading screen
				loading_screen.queue_free()
				await get_tree().process_frame
				# Cambia scena
				get_tree().change_scene_to_packed(loaded_scene)
				return
				
			ResourceLoader.THREAD_LOAD_FAILED:
				loading_screen.queue_free()
				get_tree().change_scene_to_file(scene_path)
				return

# Options

func _on_back_pressed():
	close_options()
	
func close_options():
	if options_menu:
		options_menu.visible = false
		main_menu_ui.visible = true
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
		
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if options_menu and options_menu.visible:
			_on_back_pressed()
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
