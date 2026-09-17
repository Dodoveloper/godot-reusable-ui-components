// Downloaded from https://godotshaders.com/shader/darkened-blur/
shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 5.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float mix_percentage: hint_range(0.0, 1.0) = 0.3;

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	color = mix(color, vec4(0,0,0,1), mix_percentage);
	COLOR = color;
}