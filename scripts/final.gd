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
# Colore del testo del player (Bianco)
var player_text_color := Color.WHITE

# Dialogo Finale
var dialogue_sequence := [
	{ "speaker": "player", "text": "You.. you're the same girl I was about to run over." },
	{ "speaker": "girl", "text": "..." },
	
	{ "speaker": "player", "text": "Why are you here too? Do you know how to get out of here?" },
	{ "speaker": "girl", "text": "A way out of here?" },
	{ "speaker": "girl", "text": "You know you're never leaving here again, right?" },
	{ "speaker": "girl", "text": "Oh.. right... you don't know it." },
	
	{ "speaker": "player", "text": "What I don't know?" },
	{ "speaker": "player", "text": "Don't mess with me because you're in serious trouble too, with those creatures out there." },
	{ "speaker": "girl", "text": "Those creatures?, you're afraid of them, right?" },
	{ "speaker": "player", "text": "Yes but I'm trying to escape from them, I'm sure we can still get out of this" },
	{ "speaker": "girl", "text": "How were you sure that if you continued down the sewers you would get out?" },
	{ "speaker": "girl", "text": "How were you also sure that if you continued down the road you would get out?" },
	{ "speaker": "girl", "text": "How were you also sure that if you fixed the car in the beginning you would get out of it?" },
	{ "speaker": "girl", "text": "But... did you think that you never fixed the car when you crashed?" },
	
	{ "speaker": "player", "text": "What you mean..." },
	{ "speaker": "player", "text": "And.. how do you know I crashed before?" },
	{ "speaker": "girl", "text": "..." },
	{ "speaker": "player", "text": "I fixed the car and tried to escape, but I saw you on the bridge in the road and I had to stop" },
	{ "speaker": "player", "text": "If it wasn't for you I would have already run away, maybe..." },
	{ "speaker": "girl", "text": "You never actually made it to the bridge." },
	{ "speaker": "girl", "text": "You never got out of that situation when you crashed." },
	{ "speaker": "girl", "text": "..." },
	{ "speaker": "girl", "text": "Because you already dead." },
	
	{ "speaker": "player", "text": "What..." },
	{ "speaker": "player", "text": "If you make fun of me again I'll leave this place alone." },
	{ "speaker": "girl", "text": "You keep saying you're leaving this place." },
	{ "speaker": "girl", "text": "Even though it's too late, you still can't understand that you'll never get out of here." },
	
	{ "speaker": "girl", "text": "The creatures that have been chasing you so far are forms recreated by the dark soul now within you." },
	{ "speaker": "girl", "text": "The creature of the forest.." },
	{ "speaker": "girl", "text": "He is the first corrupt soul that you met." },
	{ "speaker": "girl", "text": "His name is Wendigo." },
	{ "speaker": "girl", "text": "He was once one of the many Satanists." },
	{ "speaker": "girl", "text": "Only one night the Wendigo decided to perform a ritual alone." },
	{ "speaker": "girl", "text": "But he died..." },
	{ "speaker": "girl", "text": "I don't know when he died, but looking at his rotting body, I can tell he died centuries ago." },
	{ "speaker": "girl", "text": "He is looking for food because his hunger eats him inside and he will never die again.." },
	
	{ "speaker": "girl", "text": "Then.. The creature of the road.. who followed you here.." },
	{ "speaker": "girl", "text": "His name is Rake." },
	{ "speaker": "girl", "text": "I still have no idea if he was ever a living person." },
	{ "speaker": "girl", "text": "But I think he's a corrupt soul looking for victims, especially all those who were taken from the Clinton Road." },
	{ "speaker": "player", "text": "Taken from the Clinton Road?" },
	{ "speaker": "girl", "text": "Yes... Like you." },
	
	{ "speaker": "player", "text": "I can't believe it.. I just wanted to go home!" },
	{ "speaker": "girl", "text": "Like a mother who wanted to go home to her children, and then died on the edge of a bridge.." },
	{ "speaker": "girl", "text": "It was an accident.." },
	{ "speaker": "girl", "text": "And she went through the same situation as you." },
	{ "speaker": "girl", "text": "But she realized long time ago that she was already dead.." },
	{ "speaker": "player", "text": "Who was she?" },
	{ "speaker": "girl", "text": "I forgotten she's name." },
	{ "speaker": "girl", "text": "Clinton Road gives you this effect, I can't remember my name." },
	{ "speaker": "girl", "text": "But it doesn't matter now, now that no one will mention us in this place anymore." },
	
	{ "speaker": "player", "text": "But how can Clinton Road be like this? Everyone should have known by now." },
	{ "speaker": "girl", "text": "The Clinton Road isn't the road that the living really known." },
	{ "speaker": "girl", "text": "People pass by on the street every day, and we watch them." },
	{ "speaker": "girl", "text": "It's the night that wants to drag someone." },
	{ "speaker": "girl", "text": "The road tries to show those who are already here, brought into the light by an oncoming car." },
	{ "speaker": "player", "text": "..." },
	
	{ "speaker": "player", "text": "So.. you already dead.." },
	{ "speaker": "girl", "text": "..." },
	{ "speaker": "player", "text": "But.. if I'm dead.. how can I understand it?, I can't understand how." },
	{ "speaker": "girl", "text": "Just think back to before your accident." },
	{ "speaker": "girl", "text": "And you'll see how things match up but you didn't realize it." },
	{ "speaker": "girl", "text": "Close your eyes." },
	{ "speaker": "girl", "text": "Think back to that moment.. and you will return to that moment..." },
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
	if dialogue_index >= dialogue_sequence.size():
		dialogue_finished = true
		end_game()
		return
		
	var line = dialogue_sequence[dialogue_index]
	var text: String = line.get("text", "")
	var speaker: String = line.get("speaker", "player")
	
	match speaker:
		"girl":
			show_colored_text(text, girl_text_color)
		"player":
			show_colored_text(text, player_text_color)
		_:
			show_colored_text(text, player_text_color) # Fallback
			
func show_colored_text(text: String, color: Color):
	dialogue_label.text = text
	dialogue_label.add_theme_color_override("font_color", color)
	dialogue_label.visible = true
	dialogue_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 1.0, 0.3)
		
func _unhandled_input(event):
	if dialogue_started and not dialogue_finished and event.is_action_pressed("ui_accept"):
		dialogue_index += 1
		show_current_line()
			
func show_girl_text(text: String):
	show_colored_text(text, girl_text_color)
	
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
