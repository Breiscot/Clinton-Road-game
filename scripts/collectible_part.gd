extends Area3D

@export var part_id := "battery" # "battery", "fuel", "spark_plug"
@export var part_display_name := "Battery"

@onready var mesh := $MeshInstance3D
@onready var label := $Label3D
@onready var light := $OmniLight3D if has_node("OmniLight3D") else null

var player_in_range := false
var player_ref: CharacterBody3D = null
var is_collected := false

# Animazione
var float_time := 0.0
var base_y := 0.0

func _ready():
	add_to_group("collectibles")
	
	base_y = position.y
	
	# Connetti segnali
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Nascondi label inizialmente
	if label:
		label.visible = false
		
	# Colore in base tipo
	apply_part_color()
	
func apply_part_color():
	var mat := StandardMaterial3D.new()
	
	match  part_id:
		"battery":
			mat.albedo_color = Color(0.2, 0.6, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.3, 0.1)
		"fuel":
			mat.albedo_color = Color(0.8, 0.2, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.1, 0.1)
		"spark_plug":
			mat.albedo_color = Color(0.8, 0.8, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.3, 0.1)
			
	mat.emission_energy_multiplier = 0.5
	
	if mesh:
		mesh.material_override = mat
		
func _process(delta):
	if is_collected:
		return
		
	# Animazione fluttuante
	float_time += delta
	position.y = base_y + sin(float_time * 2) * 0.1
	
	# Rotazione lenta
	rotation.y += delta * 0.5
	
	# Mostra/Nascondi label
	if label:
		label.visible = player_in_range
		
	# Luce pulsa
	if light:
		light.light_energy = 0.3 + sin(float_time * 3) * 0.2
		
func _input(event):
	if not player_in_range or is_collected:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		collect()
		
func collect():
	print("Collecting: ", part_display_name)
	is_collected = true
	
	# Aggiungi la parte alla macchina
	var car = get_tree().get_first_node_in_group("crashed_car")
	if car and car.has_method("add_part"):
		car.add_part(part_id)
		
	# Animazione raccolta
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.parallel().tween_property(self, "position:y", position.y + 2, 0.3)
	tween.tween_callback(func():
		queue_free()
	)
	
func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		
func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
