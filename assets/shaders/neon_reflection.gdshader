shader_type canvas_item;
render_mode blend_add;

uniform float time_scale: hint_range(0.0, 5.0) = 0.8;
uniform float base_alpha: hint_range(0.0, 0.5) = 0.18;
uniform vec3 color_a: source_color = vec3(0.2, 0.9, 1.0);
uniform vec3 color_b: source_color = vec3(0.65, 0.08, 1.0);
uniform vec3 color_c: source_color = vec3(1.0, 0.52, 0.1);

void fragment() {
	float t = TIME * time_scale;
	float ripple = sin(UV.x * 22.0 + t * 2.8) * 0.004;
	float disturb = (sin(UV.x * 14.0 - t * 1.6) + 1.0) * 0.5;

	// Fade: strong at top of strip (adjacent to ground), fades out downward
	float fade = (1.0 - UV.y) * (1.0 - UV.y);
	fade *= 0.75 + sin(UV.x * 18.0 + t * 1.2 + ripple * 80.0) * 0.25;

	float band = UV.x + ripple + t * 0.04;
	float mix_ab = (sin(band * 2.8) + 1.0) * 0.5;
	float mix_c = max(0.0, sin(band * 6.5 + 1.2)) * 0.38;

	vec3 col = mix(color_a, color_b, mix_ab);
	col = mix(col, color_c, mix_c * disturb);

	COLOR = vec4(col, base_alpha * fade * (0.65 + disturb * 0.35));
}
