extends Node3D

enum Phase { INTRO, DRIVE, SEE_CREATURE, APPROACH, SWERVE_AND_CRASH, BLACK_TEXT, REVEAL, POST, BLINK, GIRL_APPEAR }

# Parametri
@export var drive_speed := 22.0
@export var slow_speed := 12.0
@export var crash_time := 1.2
@export var swerve_angle := 20.0
@export var black_text_time := 2.5
@export var fade_in_time := 2.0
@export var intro_time := 3.0
@export var intro_fade_time := 1.5
@export var blink_time := 0.15

@export var post_lines: Array[String] = []

# Nodi principali
@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var car: Node3D = $Path3D/PathFollow3D/Car
@onready var interior_cam: Camera3D = $Path3D/PathFollow3D/Car/InteriorCamera
@onready var exterior_cam: Camera3D = $ExteriorCamera
@onready var corpse: Node3D = $Path3D/PathFollow3D/Car/Corpse

@onready var tree: Node3D = $Tree/Tree
@onready var creature: Node3D = $Creature
@onready var girl: Node3D = $Girl

@onready var smoke_effect: GPUParticles3D = $Path3D/PathFollow3D/Car/SmokeParticles

# Markers 3D
@onready var crash_point: Marker3D = $CrashPoint
@onready var creature_trigger: Marker3D = $CreatureTrigger
@onready var swerve_trigger: Marker3D = $SwerveTrigger

# UI
@onready var black: ColorRect = $CanvasLayer/BlackOverlay
@onready var subtitle: Label = $CanvasLayer/Label
@onready var time_label: Label = $CanvasLayer/TimeLabel

# Audio
@onready var audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var audio_crash: AudioStreamPlayer3D = $AudioCrash
@onready var creature_sound: AudioStreamPlayer3D = $Creature/CreatureSound

var phase: Phase = Phase.INTRO
var post_index := 0
var input_enabled := false
var car_detached := false
var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	current_speed = drive_speed
	
	print("CreatureTrigger Z: ", creature_trigger.global_position.z)
	print("SwerveTrigger Z: ", creature.global_position.z)
	print("CrashPoint: ", crash_point.global_position)
	
	black.visible = true
	black.color.a = 0.0
	subtitle.visible = false
	time_label.visible = true
	
	# Camera
	interior_cam.current = true
	exterior_cam.current = false
	
	# Creature / Corpse / Girl
	if creature: 
		creature.visible = false
	if corpse: 
		corpse.visible = false
	if girl:
		girl.visible = false
	if smoke_effect:
		smoke_effect.emitting = false
	
	start_intro()
	
func start_intro():
	phase = Phase.INTRO
	
	await get_tree().create_timer(intro_time).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(black, "color:a", 0.0, intro_fade_time)
	tween.tween_property(time_label, "modulate:a", 0.0, intro_fade_time)
	
	await tween.finished
	
	time_label.visible = false
	
	if audio_engine and audio_engine.stream:
		audio_engine.play()
		
	phase = Phase.DRIVE
		
func _process(delta):
	match phase:
		Phase.INTRO:
			pass
			
		Phase.DRIVE:
			path_follow.progress += current_speed * delta
			
			if car.global_position.z <= creature_trigger.global_position.z:
				start_see_creature()
				
		Phase.SEE_CREATURE, Phase.APPROACH:
			current_speed = lerp(current_speed, slow_speed, delta * 2.0)
			path_follow.progress += current_speed * delta
			
			if car.global_position.z <= swerve_trigger.global_position.z:
				start_swerve_and_crash()
			
func start_see_creature():
	phase = Phase.SEE_CREATURE
	
	print("Car Z: ", car.global_position.z)
	
	if creature:
		creature.visible = true
		
	if creature_sound and creature_sound.stream:
		creature_sound.play()
		
	await get_tree().create_timer(0.3).timeout
	phase = Phase.APPROACH
	
func start_swerve_and_crash():
	phase = Phase.SWERVE_AND_CRASH
	
	print("Car position: ", car.global_position)
	print("Car rotation: ", car.rotation_degrees)
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	detach_car_from_path()
	
	if audio_crash and audio_crash.stream:
		audio_crash.play()
	
	var car_pos = car.global_position
	var target_pos = crash_point.global_position
	
	print("Distance: ", car_pos.distance_to(target_pos))
	
	var current_rot = car.rotation_degrees
	var turn_amount = +swerve_angle
	
	var impact_rotation = Vector3(
		-2,
		current_rot.y + turn_amount,
		2
	)
	
	print("Turn amount: ", turn_amount, "°")
	print("Final rotation Y: ", impact_rotation.y, "°")
	
	# Animazione
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Movimento verso il crash point
	tween.tween_property(car, "global_position", target_pos, crash_time)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
		
	tween.tween_property(car, "rotation_degrees", impact_rotation, crash_time * 0.7)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
	# Fumo
	if smoke_effect:
		smoke_effect.emitting = true
	
	# Schermo nero
	black.color.a = 1.0
	subtitle.visible = true
	subtitle.text = "I... I feel so cold.."
	phase = Phase.BLACK_TEXT
	
	await get_tree().create_timer(black_text_time).timeout
	
	start_reveal()
	
func detach_car_from_path():
	if car_detached:
		return
	
	# Salva la transform global
	var global_trans = car.global_transform
	# Rimuove dal PathFollow3D
	path_follow.remove_child(car)
	
	add_child(car)
	
	# Ripristina la transform global
	car.global_transform = global_trans
	
	interior_cam.current = true
	
	car_detached = true

	print("Car detached at: ", car.global_position)
	
func start_reveal():
	phase = Phase.REVEAL
	
	interior_cam.current = false
	exterior_cam.current = true
	
	if corpse:
		corpse.visible = true
		
	if creature:
		creature.visible = false
	
	subtitle.visible = false
	
	var tween = create_tween()
	tween.tween_property(black, "color:a", 0.0, fade_in_time)
	await tween.finished
	
	if post_lines.size() > 0:
		phase = Phase.POST
		post_index = 0
		input_enabled = true
		show_post_line()
	else:
		start_blink_and_girl()
		
func _unhandled_input(event):
	if phase != Phase.POST or not input_enabled:
		return
	
	if event.is_action_pressed("ui_accept"):
		post_index += 1
		show_post_line()
		
func show_post_line():
	if post_index >= post_lines.size():
		subtitle.visible = false
		input_enabled = false
		end_sequence()
		return
		
	subtitle.visible = true
	subtitle.text = post_lines[post_index]
	
func start_blink_and_girl():
	phase = Phase.BLINK
	
	await get_tree().create_timer(1.0).timeout
	
	# Blink veloce
	var blink_tween = create_tween()
	blink_tween.tween_property(black, "color:a", 1.0, blink_time)
	await blink_tween.finished
	
	if girl:
		girl.visible = true
	
	phase = Phase.GIRL_APPEAR
	
	await get_tree().create_timer(3.0).timeout
	
	end_sequence()

func end_sequence():
	var tween = create_tween()
	tween.tween_property(black, "color:a", 1.0, 1.5)
	await tween.finished
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
