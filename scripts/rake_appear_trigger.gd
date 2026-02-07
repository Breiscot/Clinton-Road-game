extends Area3D

@export var key_required := "sewer_key"

@onready var rake_model: Node3D = $TheRakeModel

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	
	# Nascondi The Rake all'inizio
	if rake_model:
		rake_model.visible = false
		
func _on_body_entered(body):
	if triggered:
		return
		
	if not body.is_in_group("player"):
		return
		
	# Controlla se il player ha la chiave
	if not player_has_key(body):
		print("RakeTrigger: player doesn't have the key yet")
		return
		
	print("RakeTrigger: activated")
	triggered = true
	
	if rake_model:
		rake_model.visible = true
	
func player_has_key(player: Node) -> bool:
	if not player.has_meta("keys"):
		return false
		
	var keys = player.get_meta("keys")
	return key_required in keys
