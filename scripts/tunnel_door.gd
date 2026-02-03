extends Area3D

@export var next_scene: String = "res://scene/sewers.tscn"

var player: Node3D = null
var player_in_range := false
var can_enter := false
var first_interaction_done := false

@onready var audio_open: AudioStreamPlayer3D = $AudioOpen

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		interact()
		
func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		show_prompt("[E] Interact")
		
func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		
func show_prompt(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_prompt(text)
		
func hide_prompt():
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").hide_prompt()
		
func interact():
	hide_prompt()
	
	if can_enter:
		if audio_open:
			audio_open.play()
		# The Rake apparso
		enter_door()
	else:
		if not first_interaction_done:
			first_interaction_done = true
			show_message("The door is open, but I don't think I should go in. I should keep going down the road... I'll come back if there's trouble.")
		else:
			show_message("I should keep going... there's nothing here for me yet.")
			
func show_message(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_message(text, 4.0)
		
func enable_entry():
	can_enter = true
	print("Door: Entry enabled")
	
func enter_door():
	hide_prompt()
	
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Fade to black
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	
	# Canvas
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(overlay)
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		GameProgress.complete_chapter(2)
		get_tree().change_scene_to_file(next_scene)
	)
	
	
