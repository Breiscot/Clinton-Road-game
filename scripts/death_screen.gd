extends CanvasLayer

@onready var background := $Background
@onready var death_label := $VBoxContainer/DeathLabel
@onready var restart_button := $VBoxContainer/RestartButton
@onready var main_menu_button := $VBoxContainer/MainMenuButton

func _ready():
	visible = false
	
	# Connette pulsanti
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
func show_death_screen():
	# Mostra cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
