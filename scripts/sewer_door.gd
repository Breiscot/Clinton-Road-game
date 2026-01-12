extends Area3D

@export var required_key := "sewer_key"
@export var next_area_position := Vector3.ZERO

var player: Node3D = null
var player_in_range := false
var is_locked := true
var door_opened := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_open_door()
		
func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		update_prompt()
		
func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		
func update_prompt():
	if door_opened:
		show_prompt("[E] Enter")
	elif is_locked:
		show_prompt("[E] Locked door")
	else:
		show_prompt("[E] Open door")
		
func try_open_door():
	if door_opened:
		enter_door()
		return
		
	if not player:
		return
		
	# Controlla se ha la chiave
	var has_key := false
	if player.has_meta("keys"):
		var keys = player.get_meta("keys")
		has_key = required_key in keys
		
	if has_key:
		# Sblocca e apre
		is_locked = false
		door_opened = true
		show_message("The key works. the door is now open.")
		hide_prompt()
		
		await get_tree().create_timer(1.5).timeout
		
		if player_in_range:
			show_message("[E] Enter")
	else:
		# Non ha la chiave
		if is_locked:
			show_message("The door is locked. I need to find something here.")
		else:
			show_message("I should find a way to open this.")
			
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
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(overlay)
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.8)
	tween.tween_callback(func():
			# Teletrasporta il player
			if player:
				player.global_position = next_area_position
				player.set_physics_process(true)
				player.set_process_input(true)
				
			# Fade In
			var fade_tween = create_tween()
			fade_tween.tween_property(overlay, "color:a", 0.0, 0.8)
			fade_tween.tween_callback(func():
				canvas.queue_free()
			)
	)
	
func show_prompt(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_prompt(text)
		
func hide_prompt():
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").hide_prompt()
		
func show_message(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_message(text, 3.0)
	
	
