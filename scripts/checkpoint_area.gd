extends Area3D

@export var checkpoint_id := "area_2_entrance"
@export var spawn_offset := Vector3(0, 0, 2)

var checkpoint_set := false

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player") and not checkpoint_set:
		var spawn_pos = global_position + spawn_offset
		var spawn_rot = Vector3.ZERO
		
		spawn_rot.y = body.rotation_degrees.y
		
		CheckpointManager.set_checkpoint(spawn_pos, spawn_rot)
		
		checkpoint_set = true
