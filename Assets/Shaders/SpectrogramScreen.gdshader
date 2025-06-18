shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap_anisotropic,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_orm : hint_roughness_g,filter_nearest_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_emission : source_color, hint_default_black,filter_nearest_mipmap_anisotropic,repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy;
uniform sampler2D texture_normal : hint_roughness_normal,filter_nearest_mipmap_anisotropic,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform float clearcoat : hint_range(0,1);
uniform float clearcoat_roughness : hint_range(0,1);
uniform sampler2D texture_clearcoat : hint_default_white,filter_nearest_mipmap_anisotropic,repeat_enable;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float fov : hint_range(10.0, 170.0) = 80.0;
uniform bool foreground;

void vertex() {
	if (foreground) {
		float scale = 1.0 / tan(fov * 0.5 * PI / 180.0);
		PROJECTION_MATRIX[1][1] = -scale;
		PROJECTION_MATRIX[0][0] = scale / (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y);

		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
		POSITION.z = mix(POSITION.z, 0, -1);
	}
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	vec4 orm_tex = texture(texture_orm,base_uv);
	ROUGHNESS = orm_tex.g;
	METALLIC = orm_tex.b;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb+emission_tex)*emission_energy;
	vec2 clearcoat_tex = texture(texture_clearcoat,base_uv).xy;
	CLEARCOAT = clearcoat*clearcoat_tex.x;	CLEARCOAT_ROUGHNESS = clearcoat_roughness*clearcoat_tex.y;

	if (foreground) {
		DEPTH = 1.0 - (1.0 - FRAGCOORD.z) * 0.7;
	} else {
		DEPTH = FRAGCOORD.z;
	}
}
