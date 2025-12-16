extends Control

@onready var resume_button := $VBoxContainer/ResumeButton
@onready var options_button := $VBoxContainer/OptionsButton
@onready var main_menu_button := $VBoxContainer/MainMenuButton
@onready var quit_button := $VBoxContainer/QuitButton
@onready var options_menu := $OptionsMenu

var is_paused := false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Funziona in pausa
	
	# Button connessi
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	style_buttons()
	
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
	
func _on_resume_pressed():
	resume_game()
	
func _on_options_pressed():
	if options_menu:
		options_menu.visible = true
		$VBoxContainer.visible = false
		
func close_options():
	if options_menu:
		options_menu.visible = false
		$VBoxContainer.visible = true
		
func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
	
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
	
