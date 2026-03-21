shader_type spatial;
uniform sampler2D texture_base : source_color, hint_default_white;
uniform sampler2D texture_overlay : source_color, hint_default_white;
uniform float offset_x : hint_range(-0.07, 0.07) = 0.0;
uniform float offset_y : hint_range(-0.07, 0.07) = 0.0;
uniform float white_threshold : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec2 base_uv    = UV;
	vec2 overlay_uv = UV + vec2(offset_x, offset_y) * 0.1;

	vec4 base_color    = texture(texture_base, base_uv);
	vec4 overlay_color = texture(texture_overlay, overlay_uv);

	bool is_white = base_color.r >= white_threshold &&
	                base_color.g >= white_threshold &&
	                base_color.b >= white_threshold;

	vec3 result = (overlay_color.a > 0.0 && is_white) ? overlay_color.rgb : base_color.rgb;

	ALBEDO = result;
	ALPHA  = base_color.a;
}