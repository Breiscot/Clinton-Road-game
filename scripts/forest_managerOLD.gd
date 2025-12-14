extends Node3D

@onready var world_env := $WorldEnvironment

# Riferimento audio ambientale
@onready var wind_sound := $AmbientSounds/Wind
@onready var crickets_sound := $AmbientSounds/Crickets
@onready var owl_sound := $AmbientSounds/OwlHoot

# Generazione alberi
@export var tree_scene: PackedScene
@export var tree_count := 200
@export var forest_radius := 50.0
@export var road_width := 4.0

func _ready():
	setup_environment()
	generate_trees()
	setup_ambient_sounds()

func setup_environment():
	var env := Environment

	# Cielo notturno
	env.background_mode = Environment.BG_SKY
	env.background_color = Color(0.02, 0.02, 0.5)

	# Nebbia
	env.fog_enabled = true
	env.fog_color = Color(0.01, 0.01, 0.15)
	env.fog_density = 0.02

	# Effetti di luce
	env.glow_enabled = true
	env.glow_intensity = 0.5

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	# AmbientLight basso
	env.ambient_light_color = Color(0.05, 0.05, 0.1)
	env.ambient_light_energy = 0.2

func generate_trees():
	var trees_container = $Trees

	for i in range(tree_count):
		var angle = randf() * TAU
		var distance = randf_range(road_width + 2, forest_radius)

		var pos = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)

		# Evita l'area della strada
		if abs(pos.x) < road_width:
			continue

		var tree = tree_scene.instantiate()
		tree.position = pos
		tree.rotation.y = randf() * TAU
		tree.scale = Vector3.ONE * randf_range(0.8, 1.3)
		trees_container.add_child(tree)

func setup_ambient_sounds():
	wind_sound.play()
	crickets_sound.play()

	# Suono gufo
	var owl_timer = Timer.new()
	owl_timer.wait_time = randf_range(15.0, 45.0)
	owl_timer.one_shot = false
	owl_timer.timeout.connect(_on_owl_timer)
	add_child(owl_timer)
	owl_timer.start()

func _on_owl_timer():
	if randf() < 0.5:
		owl_sound.position = Vector3(
			randf_range(-30, 30),
			randf_range(5, 15),
			randf_range(-30, 30)
		)
		owl_sound.play()
