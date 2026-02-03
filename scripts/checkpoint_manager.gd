extends Node

var checkpoint_position: Vector3 = Vector3.ZERO
var checkpoint_rotation: Vector3 = Vector3.ZERO
var has_checkpoint := false
var checkpoint_scene_path: String = ""

func _ready():
	print("CheckpointManager AutoLoad Ready.")

func set_checkpoint(position: Vector3, rotation: Vector3, scene_path: String = ""):
	checkpoint_position = position
	checkpoint_rotation = rotation
	has_checkpoint = true
	
	if scene_path != "":
		checkpoint_scene_path = scene_path
	else:
		checkpoint_scene_path = get_tree().current_scene.scene_file_path
		
	print("CheckPoint: Position: ", checkpoint_position)
	print("CheckPoint: Rotation: ", checkpoint_rotation)
	print("CheckPoint: Scene: ", checkpoint_scene_path)
	print("CheckPoint: has checkpoint: ", has_checkpoint)
		
func clear_checkpoint():
	has_checkpoint = false
	checkpoint_position = Vector3.ZERO
	checkpoint_rotation = Vector3.ZERO
	checkpoint_scene_path = ""
	print("Checkpoint cleared.")
	
func respawn_player() -> bool:
	print(" has_checkpoint: ", has_checkpoint)
	
	if not has_checkpoint:
		print("ERR. No checkpoints set")
		return false
		
	var player = get_tree().get_first_node_in_group("player")
	print(" Player found = ", player != null)
	
	if player:
		player.global_position = checkpoint_position
		player.rotation_degrees = checkpoint_rotation
		print(" Player moved to: ", checkpoint_position)
		return true
		
	return false
	
func get_checkpoint_data() -> Dictionary:
	return {
		"has_checkpoint": has_checkpoint,
		"position": checkpoint_position,
		"rotation": checkpoint_rotation,
		"scene": checkpoint_scene_path
	}
