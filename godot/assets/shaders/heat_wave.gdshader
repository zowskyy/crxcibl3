// Full-screen heat wave screen-space distortion.
// Ported from alfredbaudisch/godot-shaders Wave.shader (Godot 3 → 4).
// Applied to a full-screen ColorRect on a CanvasLayer above the game.
// intensity drives strength: 0.0 = invisible (passes through), 1.0 = full warp.
// TestRoom._process() sets intensity based on GameState.heat / HEAT_MAX.
//
// Godot 4 screen-texture fix: ColorRect has no sprite texture — TEXTURE on a
// ColorRect is the engine's default white 1x1, which painted the whole screen
// white on Android (GLES3 is strict; the editor was lenient). Screen-space
// effects must use a hint_screen_texture uniform instead.
shader_type canvas_item;

uniform float speed     : hint_range(1.0, 30.0) = 10.0;
uniform float waves     : hint_range(5.0, 120.0) = 60.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float remap01(float value, float from1, float to1) {
	return (value - from1) / (to1 - from1);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float offset = remap01(sin(uv.y * waves - (TIME * speed)), -1.0, 1.0) - 0.5;
	uv.x += offset * intensity * 0.015;  // scale so full intensity = subtle warp
	COLOR = texture(screen_texture, uv);
}
