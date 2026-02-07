extends CanvasLayer

@onready var message_label := $MessageLabel
var prompt_label: Label = null
var prompt_timer: Timer = null
#var message_container: Control = null
#var prompt_container: Control = null

func _ready():
	print("MessageUI ready")
	layer = 10
	message_label.visible = false
	
	create_prompt_label()

func create_prompt_label():
	# PromptContainer
	var container = Control.new()
	container.name = "PromptContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# PromptLabel
	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(prompt_label)
	
	prompt_timer = Timer.new()
	prompt_timer.one_shot = true
	prompt_timer.timeout.connect(hide_prompt)
	add_child(prompt_timer)
	
func show_message(text: String, duration := 4.5):
	print("showing message on screen: ", text)
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_label.visible = false)
		
func _process(delta):
	if prompt_label and prompt_label.visible:
		var screen_size = get_viewport().get_visible_rect().size
		prompt_label.size.x = screen_size.x
		prompt_label.position.x = 0
		prompt_label.position.y = screen_size.y - 100
	
func show_prompt(text: String):
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = true
		
		var screen_size = get_viewport().get_visible_rect().size
		prompt_label.position.x = (screen_size.x / 2) - (prompt_label.size.x / 2)
		prompt_label.position.y = screen_size.y -100
		
		if prompt_timer:
			prompt_timer.stop()
			prompt_timer.start(0.5)
		
func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = ""
