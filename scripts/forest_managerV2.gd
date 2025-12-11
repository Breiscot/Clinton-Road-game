extends Node3D

func _ready():
	setup_environment()
	print("Forest ready")
	
func setup_environment():
	var world_env: WorldEnvironment
	
	if has_node("WorldEnvironment"):
		world_env = $WorldEnvironment
	else:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
		
	# Crea Environment
	var env := Environment.new()
	
	# Cielo notturno scuro
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	
	#Luce ambiente bassa
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.1, 0.15)
	env.fog_density = 0.02
	
	world_env.environment = env
