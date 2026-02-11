extends Node

enum CheckpointType { NONE, SCENE, POSITION }

var checkpoint_type: CheckpointType = CheckpointType.NONE
var checkpoint_scene_path := ""
var checkpoint_position := Vector3.ZERO
var checkpoint_rotation := Vector3.ZERO

func _ready():
	print("CheckpointManager AutoLoad Ready.")

# Checkpoint: SCENE
func set_scene_checkpoint(scene_path: String):
	checkpoint_position = Vector3.ZERO
	checkpoint_rotation = Vector3.ZERO
	
	checkpoint_type = CheckpointType.SCENE
	checkpoint_scene_path = scene_path
	
	print("=== Scene Checkpoint SET ===")
	print(" Type: SCENE")
	print(" Scene path: ", scene_path)
	
# Checkpoint: POSITION
func set_position_checkpoint(position: Vector3, rotation: Vector3):
	checkpoint_scene_path = ""
	
	checkpoint_type = CheckpointType.POSITION
	checkpoint_position = position
	checkpoint_rotation = rotation
	
	print("=== Position Checkpoint SET ===")
	print(" Type: POSITION")
	print(" Position: ", position)
	print(" Rotation: ", rotation)
	
func has_checkpoint() -> bool:
	return checkpoint_type != CheckpointType.NONE
	
func is_scene_checkpoint() -> bool:
	return checkpoint_type == CheckpointType.SCENE
	
func is_position_checkpoint() -> bool:
	return checkpoint_type == CheckpointType.POSITION
		
func clear_checkpoint():
	checkpoint_type = CheckpointType.NONE
	checkpoint_scene_path = ""
	checkpoint_position = Vector3.ZERO
	checkpoint_rotation = Vector3.ZERO
	print("Checkpoint cleared.")
