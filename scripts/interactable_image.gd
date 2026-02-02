extends Area3D
class_name InteractableImage

@export var image_texture: Texture2D
@export var interaction_prompt := "Press [E] to view"

var player_in_range := false
var is_viewing := false

var image_viewer_ui: Control

signal image_opened
signal image_closed

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	await get_tree().process_frame
	image_viewer_ui = get_tree().get_first_node_in_group("image_viewer")
	
	if image_viewer_ui:
		print("ImageViewer UI found")
	else:
		print("ERR: ImageViewer UI not found")
		
func _unhandled_input(event):
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact"): # [E]
		if is_viewing:
			close_image()
		else:
			open_image()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_cancel") and is_viewing: # [ESC]
		close_image()
		get_viewport().set_input_as_handled()
		
func open_image():
	if not image_viewer_ui or not image_texture:
		return
		
	is_viewing = true
	image_viewer_ui.show_image(image_texture)
	
	# Mette in pausa il gioco
	get_tree().paused = true
	
	# Mostra il cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	emit_signal("image_opened")
	
func close_image():
	if not image_viewer_ui:
		return
		
	is_viewing = false
	image_viewer_ui.hide_image()
	
	# Riprende il gioco
	get_tree().paused = false
	
	# Nascondi il cursore
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	emit_signal("image_closed")
	
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
	
	
