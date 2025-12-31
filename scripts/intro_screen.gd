extends Control

@onready var intro_label := $TextContainer/IntroLabel
@onready var skip_label := $SkipLabel
@onready var intro_sound := $IntroSound

var intro_texts := [
	"Clinton Road, New Jersey",
	"11:47 PM",
	"...",
	"I was driving home late at night...",
	"To go home this time I wanted to take another road",
	"The Clinton Road",
	"The road was empty... too empty.",
	"Then I saw it.",
	"Something standing in the middle of the road.",
	"A figure... not human.",
	"I panicked.",
	"Lost control of the car.",
	"...",
	"Now I'm stranded here.",
	"And I'm not alone."
]

var current_text_index := 0
var is_typing := false
var can_skip := false
var skip_all := false
var skip_current_text := false

func _ready():
	intro_label.text = ""
	skip_label.modulate.a = 0.5
	
	# Avvia suono
	if intro_sound and intro_sound.stream:
		intro_sound.volume_db = -10
		intro_sound.play()
	
	await get_tree().create_timer(1.0).timeout
	can_skip = true
	start_intro()
	
func start_intro():
	for i in range(intro_texts.size()):
		if skip_all:
			break
			
		current_text_index = i
		await show_text(intro_texts[i])
		
		if not skip_all:
			await get_tree().create_timer(1.5).timeout
			
	await get_tree().create_timer(1.0).timeout
	load_game()
	
func show_text(text: String):
	if skip_all:
		return
		
	is_typing = true
	skip_current_text = false
	intro_label.text = ""
	intro_label.modulate.a = 1.0
	
	# Typing effect
	for i in range(text.length()):
		if skip_all:
			intro_label.text = text
			break
			
		if skip_current_text:
			intro_label.text = text
			break
			
		intro_label.text += text[i]
		
		# Velocità typing
		if text[i] == ".":
			await get_tree().create_timer(0.3).timeout
		elif text[i] == ",":
			await get_tree().create_timer(0.15).timeout
		else:
			await get_tree().create_timer(0.05).timeout
			
	is_typing = false
	
func _input(event):
	if not can_skip:
		return
		
	# Spazio per skippare
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if is_typing:
			# Skip solo testo corrente
			skip_current_text = true
		else:
			# Skip tutta intro
			skip_all = true
			load_game()
			
func load_game():
	# Fade Out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scene/main.tscn")
	)
