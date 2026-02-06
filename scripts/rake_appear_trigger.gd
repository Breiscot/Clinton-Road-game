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
		
	# Add fear
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_fear"):
		player.add_fear(20.0)
	
func player_has_key(player: Node) -> bool:
	if not player.has_meta("keys"):
		return false
		
	var keys = player.get_meta("keys")
	return key_required in keys
	
#func start_scare_sequence():
#	if rake_model:
#		rake_model.visible = true
		
#	await flicker_light()
	
#	if rake_model:
#		rake_model.visible = false
		
	# Ripristina la luce
#	if trigger_light:
#		trigger_light.light_energy = original_light_energy
		
#func flicker_light():
#	if not trigger_light:
#		await get_tree().create_timer(rake_visible_time).timeout
#		return
		
#	for i in range(flicker_count):
#		# Luce spenta
#		trigger_light.light_energy = 0
#		await get_tree().create_timer(flicker_speed).timeout
		
		# Luce accesa
#		trigger_light.light_energy = original_light_energy * randf_range(0.5, 1.5)
#		await get_tree().create_timer(flicker_speed).timeout
		
	# Ultimo flicker fa luce spenta e the rake scompare
#	trigger_light.light_energy = 0
#	await get_tree().create_timer(flicker_speed * 2).timeout
