shader_type canvas_item;

uniform vec4 bloom_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float bloom_strength : hint_range(0.0, 5.0) = 1.2;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float bloom_radius : hint_range(0.0, 4.0) = 1.5;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float alpha_expansion : hint_range(0.0, 2.0) = 1.0;
uniform bool use_alpha = true;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec3 base_rgb = base_color.rgb;
    float alpha = clamp(base_color.a, 0.0, 1.0);

    vec2 texel = 1.0 / max(vec2(1.0), vec2(textureSize(TEXTURE, 0)));
    vec2 centered_uv = UV - vec2(0.5);
    float radial_falloff = 1.0 - smoothstep(0.0, 1.3 + alpha_expansion, length(centered_uv * vec2(1.0 + alpha_expansion, 1.0 + alpha_expansion)));

    vec3 bloom = vec3(0.0);
    float total_weight = 0.0;

    for (int x = -4; x <= 4; x++) {
        for (int y = -4; y <= 4; y++) {
            vec2 offset = vec2(float(x), float(y)) * texel * (bloom_radius + 0.75);
            vec2 sample_uv = UV + offset;
            vec4 sample_color = texture(TEXTURE, sample_uv);
            vec3 sample_bright = max(sample_color.rgb - vec3(bloom_threshold), vec3(0.0));

            float alpha_weight = clamp(sample_color.a * (1.0 + alpha_expansion), 0.0, 1.5);
            float dist = length(vec2(float(x), float(y)) / 4.0);
            float weight = exp(-(dist * dist) * 2.5) * (0.65 + alpha_weight);

            bloom += sample_bright * weight;
            total_weight += weight;
        }
    }

    if (total_weight > 0.0) {
        bloom /= total_weight;
    }

    vec3 glow = bloom * bloom_tint.rgb * bloom_strength * glow_intensity * (0.5 + alpha * 1.5) * (0.4 + radial_falloff);
    vec3 final_rgb = base_rgb + glow;

    if (use_alpha) {
        final_rgb = mix(base_rgb, final_rgb, clamp(alpha + (1.0 - alpha) * 0.35, 0.0, 1.0));
    }

    COLOR = vec4(final_rgb, alpha);
}
