extends CanvasLayer

@onready var message_label := $MessageLabel

var prompt_label: Label = null

func _ready():
	print("Message ready")
	layer = 100
	message_label.visible = false
	
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.anchor_left = 0
	message_label.anchor_right = 1
	message_label.anchor_top = 0.7
	message_label.anchor_bottom = 0.9
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	prompt_label = Label.new()
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.anchor_left = 0.5
	prompt_label.anchor_right = 0.5
	prompt_label.anchor_top = 0.6
	prompt_label.anchor_bottom = 0.65
	prompt_label.offset_left = -100
	prompt_label.offset_right = 100
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(prompt_label)
	
func show_prompt(text: String):
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = true
		
func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
	
func show_message(text: String, duration := 3.0):
	print("showing message on screen: ", text)
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	
	# Fade In
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_label.visible = false)
	
	await get_tree().create_timer(duration).timeout
	
	message_label.visible = false
