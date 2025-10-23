shader_type spatial;


render_mode blend_mix, depth_draw_always, cull_disabled, unshaded;



uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.6, 0.8);
uniform sampler2D main_texture : source_color, hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D distortion_texture : source_color, hint_default_black, filter_nearest, repeat_enable;
uniform float color_quantization_levels : hint_range(1.0, 64.0) = 16.0;

uniform vec2 main_tex_tiling = vec2(1.0, 1.0);
uniform vec2 main_tex_offset = vec2(0.0, 0.0);
uniform float texture_scroll_speed_x : hint_range(-2.0, 2.0) = 0.05;
uniform float texture_scroll_speed_y : hint_range(-2.0, 2.0) = 0.05;


uniform vec2 distortion_tex_tiling = vec2(1.0, 1.0);
uniform vec2 distortion_tex_offset = vec2(0.0, 0.0);
uniform float distortion_scroll_speed_x : hint_range(-2.0, 2.0) = 0.03;
uniform float distortion_scroll_speed_y : hint_range(-2.0, 2.0) = 0.03;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.05;
uniform vec3 ripple_center = vec3(0.0, 0.0, 0.0);
uniform float ripple_speed : hint_range(0.1, 5.0) = 1.0;
uniform float ripple_strength : hint_range(0.0, 0.2) = 0.05;
uniform float ripple_density : hint_range(1.0, 20.0) = 5.0;

uniform bool enable_waves = true;
uniform float wave_amplitude : hint_range(0.01, 1.0) = 0.1;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;

uniform bool enable_jitter = true;
uniform float jitter_intensity : hint_range(10.0, 500.0) = 150.0;
uniform bool enable_affine_texture = true;
uniform bool enable_dithering = true;

varying vec2 affine_uv;
varying float clip_w;
varying vec3 world_pos;
varying vec2 distortion_uv_varying;


float dither_pattern(vec2 screen_pos) {
	const mat4 dither_matrix = mat4(
		vec4( 0.0,  8.0,  2.0, 10.0),
		vec4(12.0,  4.0, 14.0,  6.0),
		vec4( 3.0, 11.0,  1.0,  9.0),
		vec4(15.0,  7.0, 13.0,  5.0)
	) / 16.0;
	
	ivec2 pattern_pos = ivec2(mod(screen_pos, 4.0));
	return dither_matrix[pattern_pos.x][pattern_pos.y];
}


void vertex() {
	vec4 model_pos = vec4(VERTEX, 1.0);

	if (enable_waves) {
		vec4 world_pos_for_waves = MODEL_MATRIX * model_pos;
		float wave_offset = sin(TIME * wave_speed + world_pos_for_waves.x * wave_frequency + world_pos_for_waves.z * wave_frequency) * wave_amplitude;
		model_pos.y += wave_offset;
	}

	world_pos = (MODEL_MATRIX * model_pos).xyz;

	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * model_pos;
	
	if (enable_jitter) {
		view_pos.xyz = floor(view_pos.xyz * jitter_intensity) / jitter_intensity;
	}
	
	POSITION = PROJECTION_MATRIX * view_pos;
	
	vec2 main_scaled_uv = UV * main_tex_tiling + main_tex_offset;
	distortion_uv_varying = UV * distortion_tex_tiling + distortion_tex_offset;

	if (enable_affine_texture) {
		affine_uv = main_scaled_uv * POSITION.w;
		clip_w = POSITION.w;
	} else {
		affine_uv = main_scaled_uv;
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

	vec2 distortion_uv = distortion_uv_varying + vec2(TIME * distortion_scroll_speed_x, TIME * distortion_scroll_speed_y);

	vec4 distortion_tex = textureLod(distortion_texture, distortion_uv, 0.0);
	
	vec2 distortion_offset = (distortion_tex.rg * 2.0 - 1.0) * distortion_strength;
	float dist_to_ripple_center = distance(world_pos.xz, ripple_center.xz);
	float ripple_wave = sin((dist_to_ripple_center * ripple_density) - (TIME * ripple_speed)) * ripple_strength;
	distortion_offset += vec2(ripple_wave);

	vec2 main_uv = final_uv + vec2(TIME * texture_scroll_speed_x, TIME * texture_scroll_speed_y);
	main_uv += distortion_offset;
	
	vec4 main_tex_color = textureLod(main_texture, main_uv, 0.0);
	
	vec4 final_color = water_color;
	final_color.rgb *= main_tex_color.rgb;
	final_color.a *= main_tex_color.a;
	
	final_color.rgb = floor(final_color.rgb * color_quantization_levels) / color_quantization_levels;
	
	if (enable_dithering && final_color.a < 0.99) {
		float dither_val = dither_pattern(FRAGCOORD.xy);
		if (final_color.a < dither_val) {
			discard;
		}
		final_color.a = 1.0;
	} else {
		final_color.a = 1.0;
	}
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
