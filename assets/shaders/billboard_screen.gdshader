shader_type canvas_item;

// Phase 10-C-1: billboard screen effect for the street advert panel.
// Acts on the Polygon2D UV (normalized 0..1 in shader).
// Not a full-screen shader — only covers the small billboard quad.
uniform float scanline_density : hint_range(10.0, 300.0) = 80.0;
uniform float scanline_strength : hint_range(0.0, 0.8) = 0.12;
uniform float flicker_speed : hint_range(0.0, 30.0) = 8.0;
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.04;
uniform float brightness : hint_range(0.5, 2.0) = 1.15;
uniform float edge_glow : hint_range(0.0, 1.0) = 0.3;
uniform float panel_vignette : hint_range(0.0, 1.0) = 0.2;
uniform float rgb_shift : hint_range(0.0, 0.015) = 0.002;

float rand_f(float seed) {
	return fract(sin(seed * 93.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Subtle chromatic aberration
	float r = texture(TEXTURE, uv + vec2(rgb_shift, 0.0)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - vec2(rgb_shift, 0.0)).b;
	float a = texture(TEXTURE, uv).a;
	vec4 col = vec4(r, g, b, a);

	// Overall brightness boost (screens emit light)
	col.rgb *= brightness;

	// Horizontal scanlines
	float scan = sin(uv.y * scanline_density * PI) * 0.5 + 0.5;
	col.rgb *= 1.0 - scanline_strength * (1.0 - scan);

	// Per-frame flicker
	float frame_id = floor(TIME * flicker_speed);
	col.rgb *= 1.0 - flicker_strength * rand_f(frame_id);

	// Corner vignette (slight darkening at corners)
	vec2 centered = uv * 2.0 - 1.0;
	float vig = 1.0 - panel_vignette * dot(centered, centered);
	col.rgb *= max(vig, 0.0);

	// Edge glow (phosphor-style rim brightening, blue-tinted)
	float ex = min(uv.x, 1.0 - uv.x);
	float ey = min(uv.y, 1.0 - uv.y);
	float edge_rim = 1.0 - clamp(min(ex, ey) * 10.0, 0.0, 1.0);
	col.rgb += edge_glow * edge_rim * vec3(0.8, 0.9, 1.0);

	COLOR = col;
}
