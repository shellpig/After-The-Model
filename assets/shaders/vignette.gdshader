shader_type canvas_item;

// Phase 10-B: light corner darkening. Pure overlay alpha — no screen sampling,
// so it's safe to sit above the world and below GameUI without extra passes.
uniform float intensity : hint_range(0.0, 1.0) = 0.35;
uniform float radius : hint_range(0.1, 1.5) = 0.75;
uniform float softness : hint_range(0.05, 1.0) = 0.55;

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float dist = length(centered);
	float vignette = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * intensity);
}
