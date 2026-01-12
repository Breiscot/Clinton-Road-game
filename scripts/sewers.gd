extends Node3D

@onready var player := $Player

var intro_shown := false

func _ready():
	setup_environment()
	
	await get_tree().create_timer(2.0).timeout
	show_intro_messages()
	
func setup_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#050505")
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#0a0a0a")
	env.ambient_light_energy = 0.02
	
	env.fog_enabled = true
	env.fog_light_color = Color("#0a0a0a")
	env.fog_density = 0.02
	
	world_env.environment = env
	add_child(world_env)
	
func show_intro_messages():
	if intro_shown:
		return
	intro_shown = true
	
	show_message("I don't think I want to go back out on the street with that thing waiting for me.")
	
	await get_tree().create_timer(5.0).timeout
	show_message("These sewers... There must be a way out of here.")
	
func show_message(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_message(text, 3.5)
