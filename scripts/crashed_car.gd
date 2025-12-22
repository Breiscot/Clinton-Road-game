extends Node3D

# Particelle
var smoke_particles: GPUParticles3D = null
var glass_particles: GPUParticles3D = null

# Luci
@onready var headlight_left := $Headlights/HeadlightLeft if has_node("Headlights/HeadlightLeft") else null
@onready var hazard_left := $Hazardlights/HazardLeft if has_node("Hazardlights/HazardLeft") else null
@onready var hazard_right := $Hazardlights/HazardRight if has_node("Hazardlights/HazardRight") else null

# Fumo
@onready var smoke := $SmokeParticles

# Interazione
var interaction_area: Area3D = null
var interaction_prompt: Node3D = null
var prompt_label: Label3D = null
var player_in_range := false
var player_ref: CharacterBody3D = null

# Sistema Riparazione
var required_parts := 3
var collected_parts := 0
var part_names := ["Battery", "Fuel Can", "Spark Plug"]
var parts_collected := {
	"battery":  false,
	"fuel": false,
	"spark plug": false
}
var car_repaired := false

# Timer luci
var hazard_timer := 0.0
var hazard_on := false
var headlight_flicker_timer := 0.0

# Segnali
signal car_repaired_signal
signal part_collected(part_name: String, total: int, required: int)
signal interaction_availble(availble: bool)

func _ready():
	add_to_group("crashed_car")
	
	setup_car_damage()
	setup_smoke_particles()
	setup_interaction_area()
	setup_interaction_prompt()
	start_effects()
	
	print("Crashed car ready")
	print("Parts needed: ", required_parts)
	
func setup_car_damage():
	# Posiziona la testa fuori strada
	position.x += 2.5
	
func setup_smoke_particles():
	

func start_effects():
	# Fumo che esce dal motore
	if smoke_particles:
		smoke_particles.emitting = true

func _process(delta):
	update_hazard_lights(delta)
	update_headlight_flicker(delta)

func update_hazard_lights(delta):
	hazard_timer += delta
	if hazard_timer >= 0.8:
		hazard_timer = 0.0
		hazard_on = !hazard_on
		hazard_left.visible = hazard_on
		hazard_right.visible = hazard_on

		# Luce delle frecce
		if hazard_on:
			hazard_left.light_color = Color(1.0, 0.5, 0.0)
			hazard_right.light_color = Color(1.0, 0.5, 0.0)

func update_headlight_flicker(delta):
	headlight_flicker_timer += delta

	# Faro sinistro danneggiato che lampeggia
	if headlight_flicker_timer >= randf_range(0.1, 0.5):
		headlight_flicker_timer = 0.0
		if randf() > 0.3:
			headlight_left.light_energy = randf_range(0.3, 1.0)
		else:
			headlight_left.light_energy = 0.0
