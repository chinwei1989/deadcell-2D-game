// Darkens the screen edges (cold, near-black tint) so the eye stays on the action.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.02, 0.04, 0.06, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float inner : hint_range(0.0, 1.0) = 0.42;
uniform float outer : hint_range(0.0, 1.5) = 0.9;

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x; // Keep it round on wide screens.
	float edge = smoothstep(inner, outer, length(uv));
	COLOR = vec4(tint.rgb, edge * strength);
}
