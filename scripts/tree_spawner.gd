extends Node3D

@export var tree_scene: PackedScene
@export var tree_count: int = 200
@export var spawn_radius: float = 50.0
@export var min_distance_from_center: float = 5.0

@export var road_width: float = 6.0
@export var road_direction: String = "Z"

@export var min_scale: float = 3.7
@export var max_scale: float = 4.7
@export var random_rotation: bool = true

@export var min_tree_distance: float = 1.0

var tree_positions: Array[Vector3] = []

func _ready():
	generate_trees()
	
func generate_trees():
	if tree_scene == null:
		print("Nessuna scena albero inserita")
		return
		
	print("Generating ", tree_count, "trees..")
	
	var trees_created := 0
	var max_attempts := tree_count * 10
	var attempts := 0
	
	while trees_created < tree_count and attempts < max_attempts:
		attempts += 1
		
		# Genera posizioni casuali
		var pos := get_random_position()
		
		# Controlla se la posizione va bene
		if is_valid_position(pos):
			spawn_tree(pos)
			tree_positions.append(pos)
			trees_created += 1
			
	print("Created ", trees_created, " trees in ", attempts, " attempts")
	
	# Bake navigation automatico dopo aver creato gli alberi
	await get_tree().physics_frame
	var nav_region = get_tree().get_first_node_in_group("navigation") as NavigationRegion3D
	if nav_region:
		nav_region.bake_navigation_mesh()
	
func get_random_position() -> Vector3:
	# Genera posizione casuale nel "cerchio"
	var angle := randf() * TAU
	var distance := randf_range(min_distance_from_center, spawn_radius)
	
	var x := cos(angle) * distance
	var z := sin(angle) * distance
	
	return Vector3(x, 0, z)
	
func is_valid_position(pos: Vector3) -> bool:
	# Controlla se è sulla strada
	if road_direction == "Z":
		if abs(pos.x) < road_width / 2.0:
			return false
	else:
		if abs(pos.z) < road_width / 2.0:
			return false
			
	# Controlla distanza da altri alberi
	for existing_pos in tree_positions:
		var dist := pos.distance_to(existing_pos)
		if dist < min_tree_distance:
			return false
			
	# Controlla che e' dentro il raggio
	if pos.length() > spawn_radius:
		return false
		
	return true
	

	
func spawn_tree(pos: Vector3):
	# Crea instanza dell'albero
	var tree := tree_scene.instantiate()
	# Posizione
	tree.position = pos
	# Rotazione casuale
	if random_rotation:
		tree.rotation.y = randf() * TAU
	# Scala casuale
	var random_scale := randf_range(min_scale, max_scale)
	tree.scale = Vector3.ONE * random_scale
	# Collisione
	add_tree_collision(tree, random_scale)
	
	add_child(tree)
	
func add_tree_collision(tree: Node3D, tree_scale: float):
	# Crea StaticBody3D
	var static_body := StaticBody3D.new()
	static_body.name = "TreeCollision"
	# Crea la forma
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	# Dimensioni
	shape.radius = 0.02 * tree_scale
	shape.height = 0.02 * tree_scale
	
	collision.shape = shape
	collision.position.y = (shape.height / 2.0)
	
	static_body.add_child(collision)
	tree.add_child(static_body)
