extends Node3D

enum Phase { DRIVE, SEE_CREATURE, SWERVE, CRASH, BLACK_TEXT, REVEAL, POST }

@export var drive_speed := 12.0
@export var brake_time := 0.5
@export var swerve_time := 0.3
@export var crash_move_time := 0.4
@export var black_text_time := 2.5
@export var fade_in_time := 2.0
@export var creature_trigger_progress := 35.0

@export var post_lines: Array[String] = []

@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var car: Node3D = $Path3D/PathFollow3D/Car
@onready var interior_cam: Camera3D = $Path3D/PathFollow3D/Car/InteriorCamera
@onready var exterior_cam: Camera3D = $ExteriorCamera
@onready var corpse: Node3D = $Path3D/PathFollow3D/Car/Corpse

@onready var tree: Node3D = $Tree
@onready var creature: Node3D = $Creature

@onready var black: ColorRect = $CanvasLayer/BlackOverlay
@onready var subtitle: Label = $CanvasLayer/Label

@onready var audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var audio_crash: AudioStreamPlayer3D = $AudioCrash

var phase: Phase = Phase.DRIVE
var post_index := 0
var input_enabled := false
var car_detached := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
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
		
	print("path_follow: ")
		
func _process(delta):
	match phase:
		Phase.DRIVE:
			path_follow.progress += drive_speed * delta
			if path_follow.progress >= creature_trigger_progress:
				start_see_creature()
		Phase.SEE_CREATURE:
			if not car_detached:
				path_follow.progress += drive_speed * 0.3 * delta
			
func start_see_creature():
	phase = Phase.SEE_CREATURE
	
	if creature:
		creature.visible = true
		
	await get_tree().create_timer(brake_time).timeout
	
	start_swerve()
	
func start_swerve():
	phase = Phase.SWERVE
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	detach_car_from_path()
	
	# Calcola la direzione verso l'albero
	var tree_pos = tree.global_position
	var car_pos = car.global_position
	var direction_to_tree = (tree_pos - car_pos).normalized()
	
	# Calcola l'angolo Y
	var target_y_angle = atan2(direction_to_tree.x, direction_to_tree.z)
	# Swerve verso l'albero
	var tween = create_tween()
	tween.tween_property(car, "rotation:y", target_y_angle, swerve_time)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
		
	await tween.finished
	
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

func start_crash():
	phase = Phase.CRASH
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	if audio_crash and audio_crash.stream:
		audio_crash.play()
		
	var crash_target = tree.global_position + Vector3(0, 0.5, 0)
	var current_y_rot: float = rad_to_deg(car.rotation.y)
	var impact_rotation = Vector3(-12, current_y_rot + 25, 18)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(car, "global_position", crash_target, crash_move_time)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)
		
	tween.tween_property(car, "rotation_degrees", impact_rotation, crash_move_time)\
		.set_ease(Tween.EASE_IN)
		
	await  tween.finished
	
	var shake_tween = create_tween()
	shake_tween.tween_property(car, "position:y", car.position.y + 0.2, 0.05)
	shake_tween.tween_property(car, "position:y", car.position.y, 0.1)
	await shake_tween.finished
	
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
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
