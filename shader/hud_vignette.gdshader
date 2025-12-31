shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	
	// Calcola vignette
	float vignette = smoothstep(0.5 - vignette_softness * 0.5, 0.5, dist * (1.0 + vignette_intensity));
	
	// Intensità
	vignette *= vignette_intensity;
	
	COLOR = vec4(vignette_color.rgb, vignette);
}
