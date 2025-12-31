extends CanvasLayer

@onready var vignette_rect := $VignetteRect
var vignette_material: ShaderMaterial

func _ready():
	vignette_material = vignette_rect.material as ShaderMaterial
	set_fear_level(0.0)
	
func set_fear_level(fear_percent: float):
	var intensity = clamp(fear_percent, 0.0, 1.0)
	
	if vignette_material:
		vignette_material.set_shader_parameter("vignette_intensity", intensity * 0.8)
		vignette_material.set_shader_parameter("vignette_softness", 0.3 + intensity * 0.3)
