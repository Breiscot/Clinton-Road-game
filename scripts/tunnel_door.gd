extends Area3D

@export var next_scene: String = "res://scene/sewers.tscn"
@export var interaction_range := 2.0

var player: Node3D = null
var player_in_range := false
var can_enter := false
var message_shown := false

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
		show_interact_hint()
		
func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		hide_interact_hint()
		
func show_interact_hint():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_interact_prompt"):
		hud.show_interact_prompt("Press [E]")
		
func hide_interact_hint():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_interact_prompt"):
		hud.hide_interact_prompt()
		
func interact():
	if not can_enter:
		if not message_shown:
			message_shown = true
			show_message("The door is open, but I don't think I should go in. I should keep going down the road... I'll come back if there's trouble.")
		else:
			# The Rake presente
			enter_door()
			
func show_message(text: String):
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_node("MessageUI"):
		player_node.get_node("MessageUI").show_message(text, 4.0)
		
func enable_entry():
	can_enter = true
	print("Door: Entry enabled")
	
func enter_door():
	# Fade to black
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.set_physics_process(false)
		
	# Overlay
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
		get_tree().change_scene_to_file(next_scene)
	)
