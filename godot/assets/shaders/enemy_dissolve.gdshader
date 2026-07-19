// 2D dissolve — enemy death effect.
// Ported from alfredbaudisch/godot-shaders (Godot 3 → 4):
//   hint_color → source_color, texture2 → overlay_texture (reserved name fix).
// dissolve_progress drives the effect: 0.0 = fully visible, 1.0 = gone.
// Set via ShaderMaterial parameter from Enemy.gd during death sequence.
shader_type canvas_item;

const float BORDER_SIZE = 0.02;
const float NOISE_BORDER_SIZE = 0.05;

uniform sampler2D overlay_texture : source_color;
uniform sampler2D noise_texture : filter_linear;
uniform float noise_speed : hint_range(0.1, 5.0) = 1.0;
uniform vec4 border_color : source_color = vec4(1.0, 0.4, 0.0, 1.0); // orange, matches Heat
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 st = UV;
	float r = 0.1;
	st.x -= r * sin(TIME / noise_speed);
	st.y -= r * cos(TIME / noise_speed);
	vec4 noise = texture(noise_texture, st);

	// dissolve_progress drives radius: 0 = full sprite, 1 = fully dissolved
	float radius = dissolve_progress;
	float shape  = clamp(1.0 - length(UV - vec2(0.5)) * 2.0 * (1.0 - radius + 0.001), 0.0, 1.0);
	float shape2 = clamp(shape + BORDER_SIZE, 0.0, 1.0);

	vec4 sprite_color = texture(TEXTURE, UV);
	vec4 over_color   = texture(overlay_texture, UV);

	float noise_val  = noise.r * shape;
	float noise_val2 = noise.r * shape2;
	float s1 = step(noise_val,  dissolve_progress + NOISE_BORDER_SIZE);
	float s2 = step(noise_val2, dissolve_progress + NOISE_BORDER_SIZE);

	vec4 border1 = (1.0 - s1) * border_color;
	vec4 border2 = (1.0 - s2) * vec4(1.0) - border1;

	vec4 c = mix(over_color, sprite_color, s1);
	c = mix(c, border2 * border_color, border2.r);

	// Discard fully transparent fragments so the node self-destructs visually
	if (c.a < 0.01) {
		c.a = 0.0;
	}
	COLOR = c;
}
