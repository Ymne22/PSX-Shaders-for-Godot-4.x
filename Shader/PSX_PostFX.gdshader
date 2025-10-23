shader_type canvas_item;

uniform float color_depth : hint_range(2.0, 256.0) = 32.0;
uniform float dither_intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 pixel_size = vec2(320.0, 240.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

float bayer_dither(vec2 screen_pos) {
	const mat2 bayer_matrix = mat2(
		vec2(0.0, 3.0),
		vec2(2.0, 1.0)
	);
	ivec2 p = ivec2(mod(screen_pos, 2.0));
	return bayer_matrix[p.x][p.y] / 4.0;
}

void fragment() {
	vec2 pixelated_uv = floor(UV * pixel_size) / pixel_size;
	vec4 color = texture(SCREEN_TEXTURE, pixelated_uv);

	vec2 dither_pos = FRAGCOORD.xy;
	float dither = (bayer_dither(dither_pos) - 0.5) * dither_intensity;
	color.rgb += dither / (color_depth - 1.0);

	color.rgb = floor(color.rgb * color_depth) / (color_depth - 1.0);
	
	COLOR = color;
}
