// Draws one piece of a sprite frame cut in two by a blade (CorpsePiece). Pixels on the
// other side of the cut line are discarded and a strip along the cut glows with heat.
// Unshaded (so the cut can glow), so the body is darkened to roughly match the lit world.
shader_type canvas_item;
render_mode unshaded;

// The frame's rect inside the sheet, in UV (atlas frames draw with sheet UVs).
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 frame_size = vec2(64.0);
// The cut line in frame pixels: a point on it and its unit normal.
uniform vec2 cut_point = vec2(32.0);
uniform vec2 cut_normal = vec2(0.0, 1.0);
// Keep the +1 or -1 side of the cut; 0 keeps the whole frame (no cut).
uniform float side = 1.0;
uniform float edge_width = 2.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
// 1 = white-hot fresh cut, 0 = cooled.
uniform float heat = 1.0;
uniform vec3 shade = vec3(0.62, 0.66, 0.76);

void fragment() {
	vec2 p = (UV - region.xy) / region.zw * frame_size;
	float d = dot(p - cut_point, cut_normal) * side;
	if (side != 0.0 && d < 0.0) {
		discard;
	}
	COLOR.rgb *= shade;
	if (side != 0.0 && d < edge_width) {
		vec3 hot = mix(edge_color.rgb, vec3(1.0, 0.95, 0.8), heat * heat) * (1.0 + 2.5 * heat);
		COLOR.rgb = mix(COLOR.rgb, hot, clamp(heat * 1.5, 0.0, 1.0));
	}
}
