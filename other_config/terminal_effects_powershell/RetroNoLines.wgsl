const M_PI: f32 = 3.14159265;

fn gaussian2d(x: f32, y: f32, sigma: f32) -> f32 {
    return (1.0 / (sigma * sqrt(2.0 * M_PI))) * exp(-0.5 * (x * x + y * y) / (sigma * sigma));
}

fn blur(tex_coord: vec2<f32>, sigma: f32) -> vec4<f32> {
    let dims = textureDimensions(screen_texture);
    let texel_size = vec2<f32>(1.0 / f32(dims.x), 1.0 / f32(dims.y));

    var color = vec4<f32>(0.0, 0.0, 0.0, 0.0);
    let sample_count: f32 = 13.0;
    let half_sample = sample_count / 2.0;

    for (var x: f32 = 0.0; x < sample_count; x += 1.0) {
        let offset_x = (x - half_sample) * texel_size.x;
        for (var y: f32 = 0.0; y < sample_count; y += 1.0) {
            let offset_y = (y - half_sample) * texel_size.y;
            let sample_pos = tex_coord + vec2<f32>(offset_x, offset_y);
            let weight = gaussian2d(x - half_sample, y - half_sample, sigma);
            
            color += textureSample(screen_texture, screen_sampler, sample_pos) * weight;
        }
    }

    return color;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let base_color = textureSample(screen_texture, screen_sampler, in.uv);
    
    // Adjust sigma to control blur spread (default: 1.0)
    let sigma = 1.0;
    // Adjust 0.3 to control bloom/glow intensity
    let bloom_color = blur(in.uv, sigma) * 0.3;
    
    return base_color + bloom_color;
}
