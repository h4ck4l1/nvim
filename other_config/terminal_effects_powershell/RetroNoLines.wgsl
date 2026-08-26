// -------------------------------------------------------------
// Helper Functions for Retro Glow
// -------------------------------------------------------------
const M_PI: f32 = 3.14159265;

fn gaussian2d(x: f32, y: f32, sigma: f32) -> f32 {
    return 1.0 / (sigma * sqrt(2.0 * M_PI)) * exp(-0.5 * (x * x + y * y) / (sigma * sigma));
}

fn compute_glow(uv: vec2<f32>, sigma: f32) -> vec4<f32> {
    let dims = textureDimensions(screen_texture);
    let texel_width = 1.0 / f32(dims.x);
    let texel_height = 1.0 / f32(dims.y);

    var color = vec4<f32>(0.0);

    let sample_count: i32 = 13;
    let half_count: f32 = 6.0;

    for (var x: i32 = 0; x < sample_count; x += 1) {
        let offset_x = f32(x) - half_count;

        for (var y: i32 = 0; y < sample_count; y += 1) {
            let offset_y = f32(y) - half_count;
            let sample_pos = uv + vec2<f32>(offset_x * texel_width, offset_y * texel_height);
            let weight = gaussian2d(offset_x, offset_y, sigma);

            let safe_pos = clamp(sample_pos, vec2<f32>(0.0), vec2<f32>(1.0));
            color += textureSample(screen_texture, screen_sampler, safe_pos) * weight;
        }
    }

    return color;
}

// -------------------------------------------------------------
// Main Post-Processing Fragment Shader
// -------------------------------------------------------------
@fragment
fn fs_postprocess(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {

    // 1. PERFECTLY SHARP BASE TEXT
    // We remove the RGB split completely so your eyes don't strain trying to focus on separated colors.
    let base_color = textureSample(screen_texture, screen_sampler, uv);

    // 2. SOFT, WIDE AMBIENT GLOW
    // A higher sigma (3.0) makes the glow spread out nicely.
    let glow_sigma = 1.0;
    let glow_color = compute_glow(uv, glow_sigma);

    // 3. MIX THEM TOGETHER SAFELY
    // By multiplying the glow by a small number (0.15), it creates a faint halo 
    // rather than a thick smudge that destroys contrast.
    let final_color = base_color + (glow_color * 0.15);

    return final_color;
}
