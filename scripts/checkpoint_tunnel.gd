extends Area3D

@export var checkpoint_id := "before_sewers"
@export var checkpoint_scene := "res://scene/new_area_checkpoint.tscn"

var checkpoint_activated := false

func _ready():
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	print("Checkpoint ", checkpoint_id, ": Ready")
	
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
		
	if checkpoint_activated:
		return
		
	print(" Checkpoint: ", checkpoint_id, " Activated.")
	
	CheckpointManager.set_scene_checkpoint(checkpoint_scene)
		
	checkpoint_activated = true
	
