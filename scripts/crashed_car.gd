extends Node3D

@onready var headlight_left := $Headlights/HeadlightLeft
@onready var hazard_left := $Hazardlights/HazardLeft
@onready var hazard_right := $Hazardlights/HazardRight
@onready var smoke := $SmokeParticles

var hazard_timer := 0.0
var hazard_on := false
var headlight_flicker_timer := 0.0

func _ready():
	setup_car_damage()
	start_effects()

func setup_car_damage():
	# Rotazione per simulare l'incidente
	rotation_degrees = Vector3(-5, 15, 8)

	# Posiziona la testa fuori strada
	position.x += 2.5

func start_effects():
	# Fumo che esce dal motore
	smoke.emitting = true

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
