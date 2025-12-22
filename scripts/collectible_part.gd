extends Area3D

@export var part_id := "battery" # "battery", "fuel", "spark_plug"
@export var part_display_name := "Battery"

@onready var mesh := $MeshInstance3D
@onready var label := $Label3D
@onready var light := OmniLight3D if has_node("OmniLight3D") else null

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
			
