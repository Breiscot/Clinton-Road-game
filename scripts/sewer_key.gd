extends Area3D

@export var key_id := "sewer_key"
@export var glow_enabled := true

var player_in_range := false
var collected := false

@onready var mesh := $Sketchfab_Scene
@onready var light := $OmniLight3D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if light and glow_enabled:
		light.light_color = Color("#ffcc00")
		light.light_energy = 0.5
		light.omni_range = 3.0
		
func _process(delta):
	if not collected:
		# Rotazione della chiave
		if mesh:
			mesh.rotate_y(delta * 2.0)
			
		# Controllo interazione
		if player_in_range and Input.is_action_just_pressed("interact"):
			collect_key()
			
func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and not collected:
		player_in_range = true
		show_prompt("[E] Pick up key")
		
func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		
func show_prompt(text: String):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_prompt(text)
		
func hide_prompt():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").hide_prompt()
		
func collect_key():
	collected = true
	hide_prompt()
	
	var player = get_tree().get_first_node_in_group("player")
	
	# Messaggio
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_prompt("I found a key. This maybe will open that door.")
		
	# Salva che il player ha la chiave
	if player:
		if not player.has_meta("keys"):
			player.set_meta("keys", [])
		var keys = player.get_meta("keys")
		keys.append(key_id)
		player.set_meta("keys", keys)
		print("Key collected: ", key_id)
		
	queue_free()
