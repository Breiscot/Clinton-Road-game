extends Control
class_name ImageViewerUI

@onready var background: ColorRect = $ColorRect
@onready var image_display: TextureRect = $TextureRect
@onready var close_hint: Label = $Label

func _ready():
	add_to_group("image_viewer")
	
	visible = false
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if background:
		background.color = Color(0, 0, 0, 0.85)
		
	if close_hint:
		close_hint.text = "Press [E] or [ESC] to close"
		close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
func show_image(texture: Texture2D):
	if image_display and texture:
		image_display.texture = texture
		
		image_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image_display.custom_minimum_size = Vector2(800, 600)
		
	visible = true
	
func hide_image():
	visible = false
	
func _unhandled_input(event):
	if not visible:
		return
		
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		hide_image()
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
