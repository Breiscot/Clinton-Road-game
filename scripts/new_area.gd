extends Node3D

@onready var player := $Player
@onready var black_overlay :=$CanvasLayer/BlackOverlay
@onready var intro_text := $CanvasLayer/IntroText

func _ready():
	# Fade In della schermata nera
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true
	
	# Testo introduttivo
	intro_text.text = "Hours later..."
	intro_text.modulate.a = 0
	
	# Disablita player temporaneamente
	player.set_physics_process(false)
	
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property(intro_text, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(intro_text, "modulate:a", 0.0, 1.0)
	tween.tween_property(black_overlay, "color:a", 0.0, 1.5)
	tween.tween_callback(start_gameplay)
	
func start_gameplay():
	player.set_physics_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
