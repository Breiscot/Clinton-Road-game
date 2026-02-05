extends Area3D

@export var checkpoint_id := "before_sewers"
@export var spawn_offset := Vector3(0, 0.5, 0)

var checkpoint_activated := false

func _ready():
	body_entered.connect(_on_body_entered)
	
	monitoring = true
	monitorable = true
	
	print("Checkpoint ", checkpoint_id, ": Ready at ", global_position)
	
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
		
	if checkpoint_activated:
		return
		
	var spawn_pos = body.global_position + spawn_offset
	var spawn_rot = Vector3(0, body.rotation_degrees.y, 0)
	var current_scene = get_tree().current_scene.scene_file_path
	
	print(" Player position: ", body.global_position)
	print(" Scene position: ", spawn_pos)
	print(" Scene: ", current_scene)
	
	CheckpointManager.set_checkpoint(spawn_pos, spawn_rot, current_scene)
		
	checkpoint_activated = true
	
