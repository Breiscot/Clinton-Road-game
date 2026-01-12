extends Node3D

@export var key_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []
@export var key_scale := Vector3(0.3, 0.3, 0.3)

var key_spawned := false

func _ready():
	spawn_key_random()
	
func spawn_key_random():
	if key_scene == null:
		print("key_scene not set!")
		return
		
	if spawn_points.is_empty():
		print("No spawn points set!")
		return
		
	var random_index = randi() % spawn_points.size()
	var spawn_point = spawn_points[random_index]
	
	var key = key_scene.instantiate()
	key.global_position = spawn_point.global_position
	key.scale = key_scale
	add_child(key)
	
	key_spawned = true
