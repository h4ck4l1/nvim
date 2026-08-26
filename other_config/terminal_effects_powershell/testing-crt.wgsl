@fragment
fn fs_postprocess(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    // 1. CRT Barrel Distortion (Curvature)
    var cc = uv - vec2<f32>(0.5, 0.5);
    let dist = dot(cc, cc);
    let distorted_uv = uv + cc * (dist * 0.12);

    // Darken outside screen borders
    if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }

    // 2. Chromatic Aberration (RGB split)
    let offset = dist * 0.008;
    let r = textureSample(screen_texture, screen_sampler, distorted_uv + vec2<f32>(offset, 0.0)).r;
    let g = textureSample(screen_texture, screen_sampler, distorted_uv).g;
    let b = textureSample(screen_texture, screen_sampler, distorted_uv - vec2<f32>(offset, 0.0)).b;
    var color = vec4<f32>(r, g, b, 1.0);

    // 3. Scanlines
    let dims = textureDimensions(screen_texture);
    let resolution = vec2<f32>(dims);
    let scanline = sin(distorted_uv.y * resolution.y * 1.5) * 0.06;
    color = vec4<f32>(color.rgb - vec3<f32>(scanline), color.a);

    return color;
}
