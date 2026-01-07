extends SpotLight3D

@export var flicker_enabled := true
@export var min_energy := 0.5
@export var max_energy := 1.0
@export var flicker_speed := 2.0
@export var turn_off_chance := 0.02

var base_energy := 0.8
var target_energy := 0.8
var is_temporarily_off := false
var off_timer := 0.0

func _ready():
	base_energy = light_energy
	target_energy = base_energy
	
func _process(delta):
	if not flicker_enabled:
		return
		
	# Gestione spegnimento temporaneo
	if is_temporarily_off:
		off_timer -= delta
		if off_timer <= 0:
			is_temporarily_off = false
			target_energy = base_energy
	else:
		# Possibilità di spegnimento
		if randf() < turn_off_chance * delta:
			turn_off_temporarily()
			
	# Flicker leggero
	var flicker = sin(Time.get_ticks_msec() * 0.001 * flicker_speed) * 0.1
	flicker += randf_range(-0.05, 0.05)
	
	var final_energy = target_energy + flicker
	final_energy = clamp(final_energy, min_energy, max_energy)
	
	light_energy = lerp(light_energy, final_energy, delta * 10)
	
func turn_off_temporarily():
	is_temporarily_off = true
	target_energy = 0.0
	off_timer = randf_range(0.1, 0.5)
