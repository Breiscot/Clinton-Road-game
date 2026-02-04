extends Area3D
class_name InteractableImage

@export var image_texture: Texture2D
@export var interaction_prompt := "Press [E] to view"

var player_in_range := false
var is_viewing := false
var image_viewer_ui: Control = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	monitoring = true
	monitorable = true
	
	call_deferred("_find_viewer_ui")
	
func _find_viewer_ui():
	await get_tree().process_frame
	image_viewer_ui = get_tree().get_first_node_in_group("image_viewer")
	
	if image_viewer_ui:
		print("ImageViewer UI found")
	else:
		print("ERR: ImageViewer UI not found")
		
func _input(event):
	if not player_in_range:
		return
		
	if is_viewing:
		if event.is_action_pressed("interact"):
			close_image()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"): # [E]
		open_image()
		get_viewport().set_input_as_handled()
		
func open_image():
	if not image_texture:
		return
	
	if not image_viewer_ui:
		image_viewer_ui = get_tree().get_first_node_in_group("image_viewer")
		if not image_viewer_ui:
			return
		
	is_viewing = true
	hide_prompt()
	
	image_viewer_ui.show_image(image_texture)
	
	# Mette in pausa il gioco
	get_tree().paused = true
	
	# Mostra il cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func close_image():
	if not image_viewer_ui:
		return
		
	is_viewing = false
	
	if image_viewer_ui:
		image_viewer_ui.hide_image()
	
	# Riprende il gioco
	get_tree().paused = false
	
	# Nascondi il cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if player_in_range:
		show_prompt()
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		
		if is_viewing:
			close_image()
			
func show_prompt():
	var prompt_label = get_tree().get_first_node_in_group("interaction_prompt")
	if prompt_label:
		prompt_label.text = interaction_prompt
		prompt_label.visible = true
		
func hide_prompt():
	var prompt_label = get_tree().get_first_node_in_group("interaction_prompt")
	if prompt_label:
		prompt_label.visible = false
	
	
