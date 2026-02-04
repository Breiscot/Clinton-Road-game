extends Control
class_name ImageViewerUI

@onready var background: ColorRect = $Background
@onready var image_display: TextureRect = $ImageContainer/TextureRect
@onready var image_container: Control = $ImageContainer
@onready var close_hint: Label = $CloseHint

@export var max_image_width := 800
@export var max_image_height := 600

func _ready():
	add_to_group("image_viewer")
	
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if background:
		background.color = Color(0, 0, 0, 0.85)
		background.mouse_filter = Control.MOUSE_FILTER_STOP
		
	if close_hint:
		close_hint.text = "Press [E] to close"
		
func show_image(texture: Texture2D):
	if not texture:
		return
		
	if image_display:
		image_display.texture = texture
		
		var texture_size = texture.get_size()
		var target_size = calculate_fit_size(texture_size, Vector2(max_image_width, max_image_height))
		
		image_display.custom_minimum_size = target_size
		image_display.size = target_size
		
	visible = true
	
func hide_image():
	visible = false
	
func calculate_fit_size(original_size: Vector2, max_size: Vector2) -> Vector2:
	if original_size.x <= 0 or original_size.y <= 0:
		return max_size
		
	var aspect_radio = original_size.x / original_size.y
	var target_width = max_size.x
	var target_height = max_size.y
	
	if target_width / aspect_radio <= max_size.y:
		target_height = target_width / aspect_radio
	else:
		target_width = target_height * aspect_radio
		
	return Vector2(target_width, target_height)
	
func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		hide_image()
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
