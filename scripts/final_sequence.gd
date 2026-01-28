extends Node3D

enum Phase { DRIVE, SEE_CREATURE, SWERVE, CRASH, BLACK_TEXT, REVEAL, POST }

# Parametri
@export var drive_speed := 22.0
@export var brake_time := 1.5
@export var swerve_time := 1.2
@export var crash_move_time := 0.6
@export var black_text_time := 2.5
@export var fade_in_time := 2.0

@export var post_lines: Array[String] = []

# Nodi principali
@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var car: Node3D = $Path3D/PathFollow3D/Car
@onready var interior_cam: Camera3D = $Path3D/PathFollow3D/Car/InteriorCamera
@onready var exterior_cam: Camera3D = $ExteriorCamera
@onready var corpse: Node3D = $Path3D/PathFollow3D/Car/Corpse

@onready var tree: Node3D = $Tree/Tree
@onready var creature: Node3D = $Creature

# Markers 3D
@onready var crash_point: Marker3D = $CrashPoint
@onready var creature_trigger: Marker3D = $CreatureTrigger

# UI
@onready var black: ColorRect = $CanvasLayer/BlackOverlay
@onready var subtitle: Label = $CanvasLayer/Label

# Audio
@onready var audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var audio_crash: AudioStreamPlayer3D = $AudioCrash

var phase: Phase = Phase.DRIVE
var post_index := 0
var input_enabled := false
var car_detached := false
var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	current_speed = drive_speed
	
	print("CreatureTrigger position: ", creature_trigger.global_position)
	print("CrashPoint position: ", crash_point.global_position)
	print("Creature position: ", creature.global_position)
	
	black.visible = true
	black.color.a = 0.0
	subtitle.visible = false
	
	# Camera
	interior_cam.current = true
	exterior_cam.current = false
	
	# Creature / Corpse
	if creature: 
		creature.visible = false
	if corpse: 
		corpse.visible = false
	
	# Audio
	if audio_engine and audio_engine.stream:
		audio_engine.play()
		
func _process(delta):
	match phase:
		Phase.DRIVE:
			path_follow.progress += current_speed * delta
			if car.global_position.z <= creature_trigger.global_position.z:
				start_see_creature()
				
		Phase.SEE_CREATURE:
			if not car_detached:
				current_speed = lerp(current_speed, 4.0, delta * 2.0)
				path_follow.progress += current_speed * delta
			
func start_see_creature():
	phase = Phase.SEE_CREATURE
	
	print("Car Z: ", car.global_position.z)
	
	if creature:
		creature.visible = true
		
	await get_tree().create_timer(brake_time).timeout
	
	start_swerve()
	
func start_swerve():
	phase = Phase.SWERVE
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	detach_car_from_path()
	
	var car_pos = car.global_position
	var target_pos = crash_point.global_position
	
	print("Car start: ", car_pos)
	print("Crash target: ", target_pos)
	
	var mid_point = Vector3(
		lerp(car_pos.x, target_pos.x, 0.4),
		car_pos.y,
		lerp(car_pos.z, target_pos.z, 0.5)
	)
	
	# Calcola l'angolo per puntare verso il crash point
	var dir_to_crash = (target_pos - car_pos).normalized()
	var target_y_angle = atan2(dir_to_crash.x, dir_to_crash.z)
	
	print("Mid point: ", mid_point)
	print("Target angle: ", rad_to_deg(target_y_angle))
	
	# Swerve verso l'albero
	var tween_swerve = create_tween()
	tween_swerve.set_parallel(true)
	
	tween_swerve.tween_property(car, "global_position", mid_point, swerve_time)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
		
	tween_swerve.tween_property(car, "rotation:y", target_y_angle, swerve_time)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	await tween_swerve.finished
	
	start_crash()
	
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
	
func start_crash():
	phase = Phase.CRASH
	
	print("Car position: ", car.global_position)
	print("Target Tree: ", tree.global_position)
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	if audio_crash and audio_crash.stream:
		audio_crash.play()
		
	var crash_target = crash_point.global_position
	var current_rot = car.rotation_degrees
	var impact_rotation = Vector3(
		current_rot.x - 3,
		current_rot.y,
		current_rot.z + 2
	)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(car, "global_position", crash_target, crash_move_time)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)
		
	tween.tween_property(car, "rotation_degrees", impact_rotation, crash_move_time)\
		.set_ease(Tween.EASE_IN)
		
	await  tween.finished
	
	var shake_tween = create_tween()
	shake_tween.tween_property(car, "position:z", car.position.z - 0.1, 0.05)
	shake_tween.tween_property(car, "position:z", car.position.z, 0.1)
	await shake_tween.finished
	
	print("Crash a: ", car.global_position)
	
	# Schermo nero
	black.color.a = 1.0
	subtitle.visible = true
	subtitle.text = "I... I feel so cold."
	phase = Phase.BLACK_TEXT
	
	await get_tree().create_timer(black_text_time).timeout
	
	start_reveal()
	
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
		await get_tree().create_timer(3.0).timeout
		end_sequence()
		
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
	
func end_sequence():
	var tween = create_tween()
	tween.tween_property(black, "color:a", 1.0, 1.5)
	await tween.finished
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
