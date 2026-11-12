shader_type canvas_item;
render_mode unshaded;

// Old-CRT power-off: the picture squeezes to a bright horizontal line, then to a
// dot, then dies. Driven by `progress` 0..1 from crt_effect.gd.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 resolution = vec2(1280.0, 720.0);
uniform vec3 beam_color : source_color = vec3(0.65, 0.88, 1.0);

void fragment() {
	float p = clamp(progress, 0.0, 1.0);

	// Vertical collapse first, then horizontal: line -> dot.
	float sy = max(1.0 - smoothstep(0.0, 0.58, p), 0.0015);
	float sx = max(1.0 - smoothstep(0.52, 1.0, p), 0.0015);

	vec2 d = SCREEN_UV - 0.5;
	vec2 uv = d / vec2(sx, sy) + 0.5;

	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	vec3 col = texture(screen_tex, clamp(uv, vec2(0.0), vec2(1.0))).rgb * inside;

	// Phosphor heats up white as the beam compresses.
	col *= mix(1.0, 2.4, smoothstep(0.3, 0.85, p));

	// Glow around the collapsing line. Only bites once the picture is nearly a line.
	float half_h = sy * 0.5;
	float half_w = sx * 0.5;
	float band = 1.0 - smoothstep(half_h - 0.002, half_h + 0.002, abs(d.y));
	float span = 1.0 - smoothstep(half_w - 0.004, half_w + 0.004, abs(d.x));
	col += beam_color * band * span * pow(1.0 - sy, 8.0) * 2.0;

	// Scanlines, always present.
	col *= 0.88 + 0.12 * sin(SCREEN_UV.y * resolution.y * 3.14159);

	// The dot fades out at the very end.
	col *= 1.0 - smoothstep(0.88, 1.0, p);

	COLOR = vec4(col, 1.0);
}
