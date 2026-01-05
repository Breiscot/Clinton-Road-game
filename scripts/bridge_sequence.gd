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
@onready var girl := $Girl/Sketchfab_Scene2
@onready var black_overlay := $CanvasLayer/BlackOverlay
@onready var message_label := $CanvasLayer/MessageLabel
@onready var audio := $AudioStreamPlayer
@onready var brake_sound := $BrakeSound

var current_state: State = State.DRIVING
var time_elapsed := 0.0
var car_speed := 30.0
var original_camera_pos: Vector3
var fall_speed := 0.0
var fall_acceleration := 15.0
var max_fall_speed := 30.0
var fade_started := false

# Timing
var girl_appear_time := 12.0
var swerve_duration := 1.5
var crash_duration := 1.5

# Movimento
var drive_direction := Vector3(0, 0, -1)
var swerve_direction := Vector3.ZERO
var swerve_timer := 0.0
var crash_timer := 0.0

# Camera Shake per crash
var crash_shake_intensity := 0.1

# Messaggi
var message_shown_1 := false
var message_shown_2 := false
var message_shown_3 := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Nascondi girl all'inizio
	girl.visible = false
	
	# Setup Overlay
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true
	
	# Setup Messaggi
	message_label.visible = false
	message_label.modulate.a = 0
	
	original_camera_pos = camera.position
	camera.current = true
	
	# Fade In
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, 1.0)
	
	# Avvia suono motore
	if audio and audio.stream:
		audio.play()
		
	# Mostra primo messaggio dopo Fade In
	await get_tree().create_timer(2.0).timeout
	show_message_1()
		
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
			
func show_message_1():
	if message_shown_1:
		return
	message_shown_1 = true
	
	show_subtitle("What was that creature before... Thank God I escaped.", 3.0)
	
	await get_tree().create_timer(7.0).timeout
	show_message_2()
	
func show_message_2():
	if message_shown_2:
		return
	message_shown_2 = true
	
	show_subtitle("That part of the bridge looks like it needs repairs...", 3.0)
	
func show_message_3():
	if message_shown_3:
		return
	message_shown_3 = true
	
	show_subtitle("WHAT THE.. I NEED TO BRAKE!, SHIT", 2.0)
	
func show_subtitle(text: String, duration := 2.0):
	message_label.text = text
	message_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_label.visible = false)

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
	var spawn_distance := 50.0
	girl.global_position = car.global_position + drive_direction * spawn_distance
	girl.global_position.y = 0
	girl.global_position.x += 2.1
	girl.visible = true
	
	show_message_3()
	
	print("Girl appeared")
	
func process_girl_appears(delta):
	# Continua a guidare avanti
	car.global_position += drive_direction * car_speed * delta
	# Calcola distanza dalla ragazza
	var distance = car.global_position.distance_to(girl.global_position)
	# Se abbastanza vicino sterza
	if distance < 8.0:
		start_swerving()
		
func start_swerving():
	current_state = State.SWERVING
	swerve_timer = 0.0
	
	print("Swerving!")
	
	# Suono freni / brake
	if brake_sound and brake_sound.stream:
		brake_sound.play()
		
	# Direzione sterzata
	swerve_direction = Vector3(1, 0, -0.5).normalized()
	
func process_swerving(delta):
	swerve_timer += delta
	
	# Rallenta
	var slow_factor = 1.0 - (swerve_timer / swerve_duration) * 0.5
	car.global_position += swerve_direction * car_speed * slow_factor * delta
	
	# Ruota la macchina
	var rotation_speed = 2.0
	car.rotation.y += rotation_speed * delta
	
	# Camera shake crescente
	var shake = swerve_timer / swerve_duration * 0.05
	camera.position = original_camera_pos + Vector3(
		randf_range(-shake, shake),
		randf_range(-shake, shake),
		0
	)
	
	# Inizia a inclinare la camera verso il basso
	var tilt_process = swerve_timer / swerve_duration
	camera.rotation.x = lerp(camera.rotation.x, deg_to_rad(-5), delta * 2)
	
	# Dopo la sterzata c'è il crash
	if swerve_timer >= swerve_duration:
		start_crash()
		
func start_crash():
	current_state = State.CRASHING
	crash_timer = 0.0
	fall_speed = 0.0
	fade_started = false
	
	print("Crashing!")
	
	# Ferma il suono del motore
	if audio.playing:
		audio.stop()
		
	# Suono crash
	$CrashSound.play()
	
func process_crashing(delta):
	crash_timer += delta
	
	# Accelera caduta
	fall_speed += fall_acceleration * delta
	fall_speed = min(fall_speed, max_fall_speed)
	
	# La macchina cade verso il basso
	car.global_position.y -= fall_speed * delta
	
	car.global_position += drive_direction * car_speed * 0.3 * delta
	
	car.rotation.x = lerp(car.rotation.x, deg_to_rad(-45), delta * 3)
	
	car.rotation.z = lerp(car.rotation.z, deg_to_rad(15), delta * 2)
	
	# Forte shake
	var shake = crash_shake_intensity * (1.0 - crash_timer / crash_duration)
	camera.position = original_camera_pos + Vector3(
		randf_range(-shake, shake),
		randf_range(-shake, shake),
		randf_range(-shake, shake)
	)
	
	# La camera si inclina
	camera.rotation.z = lerp(camera.rotation.x, deg_to_rad(-30), delta * 4)
	camera.rotation.x = lerp(camera.rotation.z, deg_to_rad(10), delta * 2)
	
	# Fade Out
	if crash_timer >= 0.8 and not fade_started:
		fade_started = true
		start_fade_out()
		
func start_fade_out():
	current_state = State.FADE_OUT
	
	print("Fading out..")
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, 1.0)
	tween.tween_callback(go_to_new_area)
	
func go_to_new_area():
	get_tree().change_scene_to_file("res://scene/new_area.tscn")
		
	
