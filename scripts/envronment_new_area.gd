extends Node3D

func _ready():
	setup_night_environment()
	setup_moon_light()
	
func setup_night_environment():
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	
	var env = Environment.new()
	
	# Background
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#000000")
	
	# Ambient Light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#000000")
	env.ambient_light_energy = 0.02
	
	# ToneMap
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	
	# Fog
	env.fog_enabled = true
	env.fog_light_color = Color("000000")
	env.fog_density = 0.005
	
	# Glow
	env.glow_enabled = false
	
	world_env.environment = env
	add_child(world_env)
	
func setup_moon_light():
	var moon = DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_color = Color("#404040")
	moon.light_energy = 0.05
	moon.rotation_degrees = Vector3(-45, -30, 0)
	moon.shadow_enabled = true
	add_child(moon)
	
