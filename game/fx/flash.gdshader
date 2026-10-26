// Tints a sprite toward a color without losing its shape: hit flashes (white), attack
// wind-up blinks, and the teal "staggered" tint. Set `amount` 0..1 from code.
// Also applies the sprite sheet's normal map (same layout as the color sheet; UV already
// points into the sheet for atlas frames), so 2D lights shade the sprite like 3D.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D normal_sheet : hint_normal, filter_nearest;
uniform bool use_normals = false;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, tint.rgb, amount);
	if (use_normals) {
		NORMAL_MAP = texture(normal_sheet, UV).rgb;
	}
}
