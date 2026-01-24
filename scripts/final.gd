extends Node3D

@onready var player := get_tree().get_first_node_in_group("player")
@onready var entry_trigger := $EntryTrigger
@onready var dialogue_trigger := $DialogueTrigger
@onready var girl_face_target := $Girl/FaceTarget
@onready var dialogue_label := $CanvasLayer/DialogueLabel
@onready var black_screen := $CanvasLayer/BlackOverlay

var entry_triggered := false
var dialogue_started := false
var dialogue_index := 0
var dialogue_finished := false

# Colore del testo della ragazza (Rosa/Viola)
var girl_text_color := Color("#d67fff")

# Dialogo Finale
var dialogue_lines: Array[String] = [
	"You're wondering where you are, right?",
	"This isn't just a road. It's Clinton Road.",
	"The Clinton Road isn't the road that the living really known",
	"Do you remember the forest? The car stopped... the engine wouldn't start.",
	"You fixed your car.. but... do you really fixed your car?"
]

func _ready():
	dialogue_label.visible = false
	black_screen.color.a = 0
	
	# Connette Trigger
	if entry_trigger:
		entry_trigger.body_entered.connect(_on_entry_trigger)
	if dialogue_trigger:
		dialogue_trigger.body_entered.connect(_on_dialogue_trigger)
	
	setup_environment()
	
func _on_entry_trigger(body):
	if body.is_in_group("player") and not entry_triggered:
		entry_triggered = true
		show_subtitle("Come closer... I won't hurt you.", 4.0)
		
func _on_dialogue_trigger(body):
	if body.is_in_group("player") and not dialogue_started:
		start_final_sequence()
		
func start_final_sequence():
	dialogue_started = true
	dialogue_finished = false
	dialogue_index = 0
	
	# Blocca il player
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
		player.velocity = Vector3.ZERO
		
	var cam = get_viewport().get_camera_3d()
	if cam and girl_face_target:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		
		tween.tween_method(look_at_girl.bind(cam), 0.0, 1.0, 2.0)
		
	await get_tree().create_timer(2.0).timeout
	
	show_current_line()
	
func look_at_girl(weight: float, cam: Camera3D):
	var target_pos = girl_face_target.global_position
	var current_transform = cam.global_transform
	var target_transform = current_transform.looking_at(target_pos, Vector3.UP)
	
	cam.global_transform = current_transform.interpolate_with(target_transform, weight)
	
func show_current_line():
	if dialogue_index >= 0 and dialogue_index < dialogue_lines.size():
		var line = dialogue_lines[dialogue_index]
		show_girl_text(line)
	else:
		dialogue_finished = true
		end_game()
		
func _unhandled_input(event):
	if dialogue_started and not dialogue_finished and event.is_action_pressed("ui_accept"):
		dialogue_index += 1
		if dialogue_index < dialogue_lines.size():
			show_current_line()
		else:
			dialogue_finished = true
			end_game()
			
func show_girl_text(text: String):
	dialogue_label.text = text
	dialogue_label.add_theme_color_override("font_color", girl_text_color)
	dialogue_label.visible = true
	dialogue_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 1.0, 0.3)
	
func end_game():
	# FadeOut testo
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 1.0)
	
	# Fade to Black
	tween.tween_property(black_screen, "color:a", 1.0, 5.0)
	await tween.finished
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
func show_subtitle(text: String, duration: float):
	dialogue_label.text = text
	dialogue_label.add_theme_color_override("font_color", Color("#d67fff"))
	dialogue_label.visible = true
	dialogue_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(duration)
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 0.5)
	
func setup_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#050505")
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#0a0a0a")
	env.ambient_light_energy = 0.02
	
	env.fog_enabled = true
	env.fog_light_color = Color("#0a0a0a")
	env.fog_density = 0.02
	
	world_env.environment = env
	add_child(world_env)
