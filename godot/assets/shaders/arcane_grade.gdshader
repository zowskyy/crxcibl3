shader_type canvas_item;
// Arcane-inspired painterly grade: warm rim, ink shadows, saturated midtones.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.85;
uniform vec4 ink_shadow : source_color = vec4(0.04, 0.02, 0.08, 1.0);
uniform vec4 gold_rim : source_color = vec4(0.95, 0.72, 0.28, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 base = texture(screen_texture, uv);
	vec3 c = base.rgb;

	// Lift shadows toward ink purple; push highlights toward gold.
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(ink_shadow.rgb, c, smoothstep(0.0, 0.55, luma));
	graded = mix(graded, graded * vec3(1.08, 1.02, 0.92), 0.35);
	graded += gold_rim.rgb * smoothstep(0.65, 1.0, luma) * 0.12;

	// Subtle vignette — painterly frame.
	vec2 vig = uv * (1.0 - uv);
	float vignette = vig.x * vig.y * 16.0;
	vignette = pow(clamp(vignette, 0.0, 1.0), 0.35);
	graded *= mix(0.72, 1.0, vignette);

	// Edge ink (cheap neighbor contrast).
	vec2 px = SCREEN_PIXEL_SIZE;
	float edge = 0.0;
	edge += abs(dot(texture(screen_texture, uv + vec2(px.x, 0.0)).rgb, vec3(0.333)) - luma);
	edge += abs(dot(texture(screen_texture, uv + vec2(0.0, px.y)).rgb, vec3(0.333)) - luma);
	graded = mix(graded, ink_shadow.rgb, clamp(edge * 2.4, 0.0, 0.22));

	COLOR = vec4(mix(base.rgb, graded, intensity), base.a);
}
