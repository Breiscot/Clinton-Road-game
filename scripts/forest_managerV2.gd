extends Node3D

func _ready():
	setup_environment()
	setup_grass_texture()
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
	
func setup_grass_texture():
	var floor_mesh: MeshInstance3D = null
	
	if has_node("Floor/MeshInstance3D"):
		floor_mesh = $Floor/MeshInstance3D
	elif has_node("Floor"):
		for child in $Floor.get_children():
			if child is MeshInstance3D:
				floor_mesh = child
				break
				
	if floor_mesh == null:
		return
		
	# Crea materiale erba
	var grass_mat := StandardMaterial3D.new()
	
	var grass_texture = load("res://images/Grass003_1K-JPG_Color.jpg")
	if grass_texture:
		grass_mat.albedo_texture = grass_texture
	else:
		grass_mat.albedo_color = Color(0.08, 0.15, 0.05)
	
	# Ripeti texture	
	grass_mat.uv1_scale = Vector3(20, 20 ,20)
	grass_mat.roughness = 0.9
	
	floor_mesh.material_override = grass_mat
	
