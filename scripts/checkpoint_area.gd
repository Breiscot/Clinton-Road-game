extends Area3D

@export var checkpoint_id := "checkpoint_1"
@export var spawn_offset := Vector3(0, 0.5, 0)

var checkpoint_activated := false

func _ready():
	body_entered.connect(_on_body_entered)
	
	monitoring = true
	monitorable = true
	
	print("CheckpointArea '", checkpoint_id, "': Ready at ", global_position)
	
	if CheckpointManager:
		print("CheckpointArea : CheckpointManager found.")
	else:
		print("CheckpointArea : ERR. CheckpointManager not found.")
	
func _on_body_entered(body):
	print("CheckpointArea: ", checkpoint_id, ": Body entered = ", body.name)
	print(" Is in player group = ", body.is_in_group("player"))
	
	if body.is_in_group("player"):
		if checkpoint_activated:
			print("Checkpoint already activated, skipping")
			return
			
		var spawn_pos = global_position + spawn_offset
		var spawn_rot = Vector3(0, body.rotation_degrees.y, 0)
		
		print("Setting checkpoint...")
		print("Spawn position: ", spawn_pos)
		print("Spawn rotation: ", spawn_rot)
		
		CheckpointManager.set_checkpoint(spawn_pos, spawn_rot)
		
		checkpoint_activated = true
