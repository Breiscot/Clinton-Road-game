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
var is_started := false
var original_camera_pos: Vector3
var escape_direction := Vector3(0, 0, -1)
var mouse_sensitivity := 0.002
var camera_rotation := Vector2.ZERO
var max_look_angle := 80.0
var max_horizontal_angle := 120.0

func _input(event):
	if not is_started or is_fading_out:
		return
		
	if event is InputEventMouseMotion:
		camera_rotation.x -= event.relative.x * mouse_sensitivity
		camera_rotation.y -= event.relative.y * mouse_sensitivity
		
		# Limite della rotazione orizzontale
		camera_rotation.x = clamp(camera_rotation.x, deg_to_rad(-max_horizontal_angle), deg_to_rad(max_horizontal_angle))
		
		# Limite della rotazione verticale
		camera_rotation.y = clamp(camera_rotation.y, deg_to_rad(-max_look_angle), deg_to_rad(max_look_angle))

func _ready():
	# Blocca e nascondi Mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("Car node: ", car)
	print("Camera node: ", camera)
	
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
	print("Fade In started..")
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, 1.5)
	tween.tween_callback(func():
		is_started = true
		print("Fade in finisched! is_started = true")
	)
	
func _process(delta):
	if not is_started or is_fading_out:
		return
	
	time_elapsed += delta
	
	if int(time_elapsed) != int(time_elapsed - delta):
		print("Time: ", int(time_elapsed), " / ", escape_duration)
		print("Car position: ", car.global_position)
		
	# Muove la macchina in avanti
	move_environment(delta)
	
	# Shake della camera in modo leggero
	apply_camera_shake(delta)
	
	# Controlla se deve finire
	if time_elapsed >= escape_duration - 4.0 and not escape_text.visible:
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
	
	# Rotazione Mouse
	camera.rotation.x = camera_rotation.y
	camera.rotation.y = camera_rotation.x + PI
	
func show_escape_text():
	escape_text.visible = true
	escape_text.text = "You Escaped..."
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(escape_text, "modulate:a", 1.0, 2.0)
	tween.tween_property(black_overlay, "color:a", 0.5, 3.0)
	
func start_fade_out():
	is_fading_out = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(escape_text, "modulate:a", 0.0, 1.0)
	tween.tween_property(black_overlay, "color:a", 1.0, 2.0)
	tween.set_parallel(false)
	
	tween.tween_callback(go_to_main_menu)
	
func go_to_main_menu():
	if audio.playing:
		audio.stop()
		
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
