extends Node3D

enum Phase { DRIVE, SEE_CREATURE, CRASH, BLACK_TEXT, REVEAL, POST }

@export var drive_speed := 12.0
@export var brake_time := 0.7
@export var crash_move_time := 0.35
@export var black_text_time := 2.5
@export var fade_in_time := 2.0

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

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	black.visible = true
	black.color.a = 0.0
	subtitle.visible = false
	
	# Camera
	interior_cam.current = true
	exterior_cam.current = false
	
	# Creature / Corpse
	if creature: creature.visible = false
	if corpse: corpse.visible = false
	
	# Audio
	if audio_engine and audio_engine.stream:
		audio_engine.play()
		
func _process(delta):
	match phase:
		Phase.DRIVE:
			process_drive(delta)
		Phase.SEE_CREATURE:
			pass
		Phase.CRASH:
			pass
		Phase.BLACK_TEXT:
			pass
		Phase.REVEAL:
			pass
		Phase.POST:
			
			pass
			
func process_drive(delta):
	path_follow.progress += drive_speed * delta
	if path_follow.progress > 35.0:
		start_see_creature()
			
func start_see_creature():
	phase = Phase.SEE_CREATURE
	
	if creature:
		creature.visible = true
		
	await get_tree().create_timer(brake_time).timeout
	
	start_crash()
	
func start_crash():
	phase = Phase.CRASH
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	if audio_crash and audio_crash.stream:
		audio_crash.play()
		
	var crash_pos = tree.global_position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(car, "global_position", crash_pos, crash_move_time)
	tween.tween_property(car, "rotation_degrees", Vector3(-10, car.rotation_degrees.y + 30, 15), crash_move_time)
	await tween.finished
	
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
		pass
		
func _unhandled_input(event):
	if phase != Phase.POST:
		return
	if not input_enabled:
		return
	if event.is_action_pressed("ui_accept"):
		post_index += 1
		show_post_line()
		
func show_post_line():
	if post_index >= post_lines.size():
		subtitle.visible = false
		input_enabled = false
		
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
		return
		
	subtitle.visible = true
	subtitle.text = post_lines[post_index]
