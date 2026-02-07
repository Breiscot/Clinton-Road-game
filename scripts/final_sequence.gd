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
@export var blink_time := 0.3

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
@onready var continue_hint: Label = $CanvasLayer/ContinueHint
@onready var end_screen: Control = $CanvasLayer/EndScreen
@onready var title_label: Label = $CanvasLayer/EndScreen/TitleLabel
@onready var thanks_label: Label = $CanvasLayer/EndScreen/ThanksLabel
@onready var return_hint: Label = $CanvasLayer/EndScreen/ReturnHint

# Audio
@onready var audio_engine: AudioStreamPlayer3D = $Path3D/PathFollow3D/Car/AudioEngine
@onready var audio_crash: AudioStreamPlayer3D = $Path3D/PathFollow3D/Car/AudioCrash
@onready var creature_sound: AudioStreamPlayer3D = $Creature/CreatureSound

var phase: Phase = Phase.INTRO
var post_index := 0
var input_enabled := false
var car_detached := false
var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	current_speed = drive_speed
		
	if black:
		black.visible = true
		black.color = Color(0, 0, 0, 1)
		black.z_index = 100
		
	if time_label:
		time_label.visible = true
		time_label.modulate.a = 1.0
		time_label.z_index = 101
	
	subtitle.visible = false
	
	if continue_hint:
		continue_hint.visible = false
		
	if end_screen:
		end_screen.visible = false
	
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
	
	if audio_engine and audio_engine.stream:
		audio_engine.play()
	
	phase = Phase.DRIVE
	
	# Fade Out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(black, "color:a", 0.0, intro_fade_time)
	
	if time_label:
		tween.tween_property(time_label, "modulate:a", 0.0, intro_fade_time)
		
	await tween.finished
	
	if time_label:
		time_label.visible = false
	
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
	
	if creature:
		creature.visible = true
		
	if creature_sound and creature_sound.stream:
		creature_sound.play()
		
	await get_tree().create_timer(0.3).timeout
	phase = Phase.APPROACH
	
func start_swerve_and_crash():
	phase = Phase.SWERVE_AND_CRASH
	
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	detach_car_from_path()
	
	if audio_crash and audio_crash.stream:
		audio_crash.play()
	
	var car_pos = car.global_position
	var target_pos = crash_point.global_position
	
	var current_rot = car.rotation_degrees
	var turn_amount = +swerve_angle
	
	var impact_rotation = Vector3(
		-2,
		current_rot.y + turn_amount,
		2
	)
	
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
	subtitle.z_index = 102 
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
	
func start_reveal():
	phase = Phase.REVEAL
	
	interior_cam.current = false
	exterior_cam.current = true
	
	if corpse:
		corpse.visible = true
		
	if creature:
		creature.visible = false
	
	subtitle.visible = false
	
	# Fade In
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
		
func show_post_line():
	if post_index >= post_lines.size():
		subtitle.visible = false
		
		if continue_hint:
			continue_hint.visible = false
		
		input_enabled = false
		start_blink_and_girl()
		return
		
	subtitle.visible = true
	subtitle.text = post_lines[post_index]
	
	if continue_hint:
		continue_hint.visible = true
		continue_hint.text = "Press SPACE to continue"
		
func start_blink_and_girl():
	phase = Phase.BLINK
	
	if continue_hint:
		continue_hint.visible = false
	
	await get_tree().create_timer(1.0).timeout
	
	# Close Blink
	var blink_tween = create_tween()
	blink_tween.tween_property(black, "color:a", 1.0, blink_time)
	await blink_tween.finished
	
	if girl:
		girl.visible = true
		
	await get_tree().create_timer(0.2).timeout
	
	# Open Blick
	var unblink_tween = create_tween()
	unblink_tween.tween_property(black, "color:a", 0.0, blink_time)
	await unblink_tween.finished
	
	phase = Phase.GIRL_APPEAR
	
	await get_tree().create_timer(4.0).timeout
	
	show_end_screen()
	
func show_end_screen():
	print("=== END SCREEN ===")
	
	# Fade to black
	var fade_tween = create_tween()
	fade_tween.tween_property(black, "color:a", 1.0, 1.5)
	await fade_tween.finished
	
	if girl:
		girl.visible = false
		
	print("end_screen: ", end_screen)
	print("title_label: ", title_label)
	print("thanks_label: ", thanks_label)
	print("return_hint: ", return_hint)
	
	# End Screen
	if end_screen:
		end_screen.visible = true
		
		if title_label:
			title_label.text = "CLINTON ROAD"
			title_label.visible = true
			title_label.modulate.a = 0.0
			
		if thanks_label:
			thanks_label.text = "Thank you for playing"
			thanks_label.visible = true
			thanks_label.modulate.a = 0.0
			
		if return_hint:
			return_hint.text = "Press SPACE to return to Menu"
			return_hint.visible = false
			
		# Fade In Title
		await get_tree().create_timer(0.5).timeout
		var title_tween = create_tween()
		title_tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await title_tween.finished
		
		# Fade in Thanks
		await get_tree().create_timer(0.5).timeout
		var thanks_tween = create_tween()
		thanks_tween.tween_property(thanks_label, "modulate:a", 1.0, 1.0)
		await thanks_tween.finished
		
		# Mostra hint per tornare al menu
		await get_tree().create_timer(2.0).timeout
		if return_hint:
			return_hint.visible = true
			return_hint.modulate.a = 0.0
			var hint_tween = create_tween()
			hint_tween.tween_property(return_hint, "modulate:a", 1.0, 0.5)
			
		# Abilita Input
		input_enabled = true
		phase = Phase.GIRL_APPEAR
		
func _unhandled_input(event):
	if not input_enabled:
		return
		
	if event.is_action_pressed("ui_accept"):
		match phase:
			Phase.POST:
				post_index += 1
				show_post_line()
			Phase.GIRL_APPEAR:
				if end_screen and end_screen.visible:
					return_to_menu()
					
func return_to_menu():
	input_enabled = false
	
	# Fade out
	if end_screen:
		var fade_tween = create_tween()
		fade_tween.tween_property(end_screen, "modulate:a", 0.0, 0.5)
		await fade_tween.finished
		
	await get_tree().create_timer(0.5).timeout
	GameProgress.complete_chapter(3)
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
