shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D flash_tex : source_color;
uniform sampler2D noise_tex : source_color;
uniform float time_speed = 3.0;
uniform float emission_strength = 5.0;

void fragment() {
    vec2 uv = UV;

    float n = texture(noise_tex, uv + vec2(TIME * time_speed, 0.0)).r;

    vec4 base = texture(flash_tex, uv);

    vec3 fire_color = base.rgb * (0.8 + n * 0.5);

    EMISSION = fire_color * emission_strength;

    ALBEDO = fire_color;
    ALPHA = base.a;
}