extends Node3D

enum State {
	DRIVING,
	GIRL_APPEARS,
	SWERVING,
	CRASHING,
	FADE_OUT
}

@onready var car := $Car
@onready var camera := $Car/Camera3D
@onready var girl := $Girl
@onready var black_overlay := $CanvasLayer/BlackOverlay
@onready var audio := $AudioStreamPlayer3D
@onready var brake_sound := $BrakeSound

var current_state: State = State.DRIVING
var time_elapsed := 0.0
var car_speed := 30.0
var original_camera_pos: Vector3

# Timing
var girl_appear_time := 3.0
var swerve_duration := 1.5
var crash_duration := 2.0

# Movimento
var drive_direction := Vector3(0, 0, -1)
var swerve_direction := Vector3.ZERO
var swerve_timer := 0.0
var crash_timer := 0.0

# Camera Shake per crash
var crash_shake_intensity := 0.1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Nascondi girl all'inizio
	girl.visible = false
	
	# Setup Overlay
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true
	
	original_camera_pos = camera.position
	camera.current = true
	
	# Fade In
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, 1.0)
	
	# Avvia suono motore
	if audio and audio.stream:
		audio.play()
		
func _process(delta):
	time_elapsed += delta
	
	match current_state:
		State.DRIVING:
			process_driving(delta)
		State.GIRL_APPEARS:
			process_girl_appears(delta)
		State.SWERVING:
			process_swerving(delta)
		State.CRASHING:
			process_crashing(delta)
		State.FADE_OUT:
			pass
			
func process_driving(delta):
	# Muove la macchina
	car.global_position += drive_direction * car_speed * delta
	
	# Leggero shake della camera
	camera.position = original_camera_pos + Vector3(
		randf_range(-0.01, 0.01),
		sin(time_elapsed * 8.0) * 0.02,
		0
	)
	
	# Dopo appare girl
	if time_elapsed >= girl_appear_time:
		show_girl()
		
func show_girl():
	current_state = State.GIRL_APPEARS
	
	# Posiziona la ragazza davanti alla macchina
	var spawn_distance := 40.0
	girl.global_position = car.global_position + drive_direction * spawn_distance
	girl.global_position.y = 0
	girl.visible = true
	
	print("Girl appeared")
	
func process_girl_appears(delta):
	# Continua a guidare avanti
	car.global_position += drive_direction * car_speed * delta
	# Calcola distanza dalla ragazza
	var distance = car.global_position.distance_to(girl.global_position)
	# Se abbastanza vicino sterza
	if distance < 15.0:
		start_swerving()
		
func start_swerving():
	current_state = State.SWERVING
	swerve_timer = 0.0
	
	print("Swerving!")
	
	# Suono freni / brake
	if brake_sound and brake_sound.stream:
		brake_sound.play()
		
	# Direzione sterzata
	var swerve_side = 1 if randf() > 0.5 else -1
	swerve_direction = Vector3(swerve_side, 0, -0.3).normalized()
	
func process_swerving(delta):
	swerve_timer += delta
	
	# Rallenta
	var slow_factor = 1.0 - (swerve_timer / swerve_duration) * 0.5
	car.global_position += swerve_direction * car_speed * slow_factor * delta
	
	# Ruota la macchina
	var rotation_speed = 2.0
	car.rotation.y += swerve_direction.x * rotation_speed * delta
	
	# Camera shake crescente
	var shake = swerve_timer / swerve_duration * 0.05
	camera.position = original_camera_pos + Vector3(
		randf_range(-shake, shake),
		randf_range(-shake, shake),
		0
	)
