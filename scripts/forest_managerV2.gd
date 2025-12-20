extends Node3D

# Audio
var wind_player: AudioStreamPlayer3D = null
var crickets_player: AudioStreamPlayer3D = null
var owl_player: AudioStreamPlayer3D = null

func _ready():
	for child in get_children():
		child.add_to_group("road_fence")
		
	setup_environment()
	setup_grass_texture()
	setup_ambient_audio()
	print("Forest ready")
	
func setup_ambient_audio():
	var audio_container = Node3D.new()
	audio_container.name = "AmbientAudio"
	add_child(audio_container)
	
	# Wind
	wind_player = AudioStreamPlayer3D.new()
	wind_player.name = "Ambience"
	wind_player.max_distance = 100
	wind_player.volume_db = -10
	audio_container.add_child(wind_player)
	
	var wind_stream = load("res://audio/ambience/wind.ogg")
	if wind_stream:
		wind_player.stream = wind_stream
		wind_player.play()
		
	# Crickets
	crickets_player = AudioStreamPlayer3D.new()
	crickets_player.name = "Crickets"
	crickets_player.max_distance = 80
	crickets_player.volume_db = -15
	audio_container.add_child(crickets_player)
	
	var crickets_stream = load("res://audio/ambience/crickets.ogg")
	if crickets_stream == null:
		crickets_stream = load("res://audio/ambience/wind.ogg")
	if crickets_stream:
		crickets_player.stream = crickets_stream
		crickets_player.play()
		
	# Owl
	owl_player = AudioStreamPlayer3D.new()
	owl_player.name = "Owl"
	owl_player.max_distance = 50
	owl_player.volume_db = -8
	audio_container.add_child(owl_player)
	
	var owl_stream = load("res://audio/ambience/owl.ogg")
	if owl_stream:
		owl_player.stream = owl_stream
		var owl_timer = Timer.new()
		owl_timer.wait_time = randf_range(20.0, 60.0)
		owl_timer.one_shot = false
		owl_timer.timeout.connect(_on_owl_timer)
		add_child(owl_timer)
		owl_timer.start()
	
func _on_owl_timer():
	if owl_player and owl_player.stream and randf() > 0.5:
		owl_player.position = Vector3(
			randf_range(-30, 30),
			randf_range(5, 15),
			randf_range(-30, 30)
		)
		owl_player.play()
		
func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player and wind_player:
		# L'audio segue il player
		wind_player.global_position = player.global_position
		if crickets_player:
			crickets_player.global_position = player.global_position
		
		
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
	
