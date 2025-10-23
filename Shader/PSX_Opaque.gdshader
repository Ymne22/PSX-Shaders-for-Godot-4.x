shader_type spatial;

render_mode unshaded, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D main_texture : source_color, filter_nearest, repeat_enable;
uniform float jitter_intensity : hint_range(1.0, 500.0) = 24.0;
uniform vec2 tiling = vec2(1.0, 1.0);
uniform vec2 offset = vec2(0.0, 0.0);
uniform bool enable_jitter = true;
uniform bool enable_affine_texture = true;


uniform float color_depth : hint_range(2, 64) = 16.0;


varying vec2 affine_uv;
varying float clip_w;

void vertex() {
	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	
	if (enable_jitter) {
		view_pos.xyz = floor(view_pos.xyz * jitter_intensity) / jitter_intensity;
	}
	
	POSITION = PROJECTION_MATRIX * view_pos;

	vec2 scaled_uv = UV * tiling + offset;
	
	if (enable_affine_texture) {
		affine_uv = scaled_uv * POSITION.w;
		clip_w = POSITION.w;
	} else {
		affine_uv = scaled_uv;
		clip_w = 1.0;
	}
}

void fragment() {
	vec2 final_uv;
	if (enable_affine_texture) {
		final_uv = affine_uv / clip_w;
	} else {
		final_uv = affine_uv;
	}

	vec4 texture_color = textureLod(main_texture, final_uv, 0.0);
	
	vec3 final_color = texture_color.rgb * albedo_color.rgb;
	
	final_color = floor(final_color * color_depth) / color_depth;
	
	ALBEDO = final_color;
}