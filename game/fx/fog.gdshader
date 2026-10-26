// Drifting ground fog: noise that fades in toward the bottom of the screen. Drawn
// additively over the world (Atmosphere sets `offset` each frame for drift + parallax).
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.55, 0.75, 0.8, 1.0);
uniform float strength = 0.12;
uniform vec2 offset = vec2(0.0);
uniform vec2 scale = vec2(1.5, 1.0);
uniform float start = 0.5;

void fragment() {
	float n = texture(noise_texture, SCREEN_UV * scale + offset).r;
	float height = smoothstep(start, 1.0, SCREEN_UV.y);
	COLOR = vec4(fog_color.rgb * n * height * strength, 1.0);
}
