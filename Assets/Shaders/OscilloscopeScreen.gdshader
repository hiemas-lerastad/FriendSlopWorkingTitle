// NOTE: Shader automatically converted from Godot Engine 4.3.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset;
uniform vec3 uv2_scale = vec3(1.0);
uniform vec3 uv2_offset;

uniform float FOV : hint_range(20, 120) = 75;
uniform bool foreground = false;

uniform float frequency : hint_range(1.0, 100.0, 1.0) = 25.0;
uniform float amplitude : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float velocity : hint_range(0.0, 25.0, 0.5) = 5.0;
uniform float tightness : hint_range(0.0, 30.0, 0.1) = 20.0;
uniform bool quality_signal = false;
uniform vec4 wave_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	if (foreground) {
	    float scale = 1.0 / tan(FOV * 0.5 * PI / -180.0);

	    PROJECTION_MATRIX[0][0] = scale / (-VIEWPORT_SIZE.x / VIEWPORT_SIZE.y);
	    PROJECTION_MATRIX[1][1] = scale;
	}
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
    vec2 wave_uv = vec2((UV.x + 0.5) * frequency, (UV.y + 0.5) * 0.5);

    float noise = cos(wave_uv.x + TIME * random(wave_uv));
    float wave = cos(wave_uv.x + TIME * velocity) * amplitude;

    float res1 = abs(2.5 + noise - wave_uv.y * 5.0);
    float res2 = abs(2.5 + wave - wave_uv.y * 5.0);

    res1 = quality_signal ? max(res1, 1.0) : res1;

    float res = res1 * res2;

    float color = (1.0 - res * tightness);

    color = clamp(color, 0.0, 1.0);

    EMISSION = color * wave_color.rgb;

	if (foreground) {
		DEPTH = 1.0 - (1.0 - FRAGCOORD.z) * 0.7;
	} else {
		DEPTH = FRAGCOORD.z;
	}
}
