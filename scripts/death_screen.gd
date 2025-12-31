extends CanvasLayer

@onready var background := $Background
@onready var death_label := $VBoxContainer/DeathLabel
@onready var restart_button := $VBoxContainer/RestartButton
@onready var main_menu_button := $VBoxContainer/MainMenuButton

func _ready():
	add_to_group("death_screen")
	layer = 100
	visible = false
	
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connette pulsanti
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
func show_death_screen():
	# Mostra cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Prepara animazione
	background.modulate.a = 0
	death_label.modulate.a = 0
	restart_button.modulate.a = 0
	main_menu_button.modulate.a = 0
	
	visible = true
	
	# Fade In
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.5)
	tween.tween_property(death_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(restart_button, "modulate:a", 1.0, 0.3)
	tween.tween_property(main_menu_button, "modulate:a", 1.0, 0.3)
	
func _on_restart_pressed():
	get_tree().reload_current_scene()
	
func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
