extends Node3D

@export var flicker_enabled := true
@export var sync_flicker := false

var lights: Array[Light3D] = []
var master_timer := 0.0

func _ready():
	find_lights(self)
	
	# Configura luci
	for light in lights:
		setup_light(light)
		
func find_lights(node: Node):
	for child in node.get_children():
		if child is OmniLight3D or child is SpotLight3D:
			lights.append(child)
		find_lights(child)
		
func setup_light(light: Light3D):
	light.light_color = Color("fff5d6")
	light.light_energy = 0.8
	
	if light is OmniLight3D:
		light.omni_range = 10
	elif light is SpotLight3D:
		light.spot_range = 12
		light.spot_angle = 70
		
func _process(delta):
	if not flicker_enabled:
		return
		
	master_timer += delta
	
	for i in range(lights.size()):
		var light = lights[i]
		update_light_flicker(light, i, delta)
		
func update_light_flicker(light: Light3D, index: int, delta: float):
	var base_energy := 0.8
	var flicker := 0.0
	
	if sync_flicker:
		# Tutte le luci flickerano
		flicker = sin(master_timer * 2.0) * 0.15
	else:
		# Ognuno ha il suo flicker
		var offset = index * 1.7
		flicker = sin(master_timer * 2.0 + offset) * 0.15
		flicker += randf_range(-0.05, 0.05)
		
	# Possibilità di spegnersi momentaneamente
	if randf() < 0.001:
		light.light_energy = 0.0
	else:
		var target = base_energy + flicker
		target = clamp(target, 0.3, 1.0)
		light.light_energy = lerp(light.light_energy, target, delta * 8)
