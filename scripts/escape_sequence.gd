extends Node3D

@export var escape_duration := 8.0
@export var car_speed := 25.0
@export var camera_shake_intensity := 0.02

@onready var car := $Car
@onready var camera := $Car/Camera3D
@onready var black_overlay := $CanvasLayer/BlackOverlay
@onready var escape_text := $CanvasLayer/EscapeText
@onready var audio := $AudioStreamPlayer

var time_elapsed := 0.0
var is_fading_out := false
var original_camera_pos: Vector3
var escape_direction := Vector3(0, 0, -1)

func _ready():
	# Nascondi il cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Setup iniziale
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true
	escape_text.visible = false
	escape_text.modulate.a = 0
	
	original_camera_pos = camera.position
	
	# Fade In iniziale
	fade_in()
	
	# Avvia audio
	if audio.stream:
		audio.play()
		
func fade_in():
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, 1.5)
	
func _process(delta):
	if is_fading_out:
		return
	
	time_elapsed += delta
	
	# Muove la macchina in avanti
	move_environment(delta)
	
	# Shake della camera in modo leggero
	apply_camera_shake(delta)
	
	# Controlla se deve finire
	if time_elapsed >= escape_duration - 3.0 and not escape_text.visible:
		show_escape_text()
		
	if time_elapsed >= escape_duration:
		start_fade_out()
		
func move_environment(delta):
	car.global_position += escape_direction * car_speed * delta
	
func apply_camera_shake(delta):
	var shake = Vector3(
		randf_range(-1, 1) * camera_shake_intensity,
		randf_range(-1, 1) * camera_shake_intensity * 0.5,
		0
	)
	camera.position = original_camera_pos + shake
	
	camera.position.y += sin(time_elapsed * 8.0) * 0.02
	
func show_escape_text():
	escape_text.visible = true
	escape_text.text = "You Escaped..."
	
	var tween = create_tween()
	tween.tween_property(escape_text, "modulate:a", 1.0, 2.0)
	
func start_fade_out():
	is_fading_out = true
	
	var tween = create_tween()
	tween.tween_property(escape_text, "modulate:a", 0.0, 1.0)
	tween.tween_property(black_overlay, "color:a", 1.0, 2.0)
	tween.tween_callback(go_to_main_menu)
	
func go_to_main_menu():
	if audio.playing:
		audio.stop()
		
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
