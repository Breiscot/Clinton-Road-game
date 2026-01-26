extends Area3D

@export var fade_duration := 1.0

@onready var audio_close: AudioStreamPlayer3D = $AudioOpen

var player_in_range := false
var player: CharacterBody3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		if player.has_node("MessageUI"):
			player.get_node("MessageUI").show_prompt("[E] Open Door")
			
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if player.has_node("MessageUI"):
			player.get_node("MessageUI").hide_prompt()
			
func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		start_teleport()
		
func start_teleport():
	if audio_close:
		audio_close.play()
	# FadeOut
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scene/final.tscn")
	)
	
	tween.tween_property(fade_rect, "color:a", 0.0, fade_duration)
	tween.tween_callback(func(): canvas.queue_free())
