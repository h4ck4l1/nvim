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
// Helper: Signed Distance to Box
// -------------------------------------------------------------
fn sd_box(p: vec2<f32>, xy: vec2<f32>, b: vec2<f32>) -> f32 {
    let d = abs(p - xy) - b;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

// -------------------------------------------------------------
// Cursor Blaze Effect
// -------------------------------------------------------------
fn compute_cursor_blaze(uv: vec2<f32>, base_color: vec4<f32>) -> vec4<f32> {
    let trail_duration: f32 = 0.45; // 450ms animation duration

    let curr = pp.current_cursor;
    var prev = pp.previous_cursor;

    // 1. Skip if cursor is hidden or inactive
    if (curr.z <= 0.0 || curr.w <= 0.0) {
        return base_color;
    }

    // 2. Prevent shooting to (0,0) on startup / tab switch
    if (prev.z <= 0.0 || prev.w <= 0.0) {
        prev = curr;
    }

    let frag_coord = uv * pp.resolution;

    // Head (Current cursor box)
    let curr_size = curr.zw * 0.5;
    let curr_pos = curr.xy + curr_size;

    // Tail (Previous cursor box)
    let prev_size = prev.zw * 0.5;
    let prev_pos = prev.xy + prev_size;

    // Displacement vector from current cursor to previous cursor
    let ba = prev_pos - curr_pos;
    let line_len_sq = dot(ba, ba);
    let line_len = sqrt(line_len_sq);

    // Ignore giant cross-screen jumps / tab switches (> half screen height)
    let max_jump = pp.resolution.y * 0.5;
    var is_valid_trail = (line_len_sq > 2.0) && (line_len < max_jump);

    // Distance to the current cursor box
    let dist_head = sd_box(frag_coord, curr_pos, curr_size);

    // Project fragment onto the FULL swept line segment (h in [0.0, 1.0])
    let pa = frag_coord - curr_pos;
    var h = 0.0;
    if (line_len_sq > 0.01) {
        h = clamp(dot(pa, ba) / line_len_sq, 0.0, 1.0);
    }

    // Distance to the continuous swept box between prev and curr
    let spine_pt = curr_pos + ba * h;
    let spine_size = mix(curr_size, prev_size, h);
    let dist_trail = sd_box(frag_coord, spine_pt, spine_size);

    // Animation progress (0.0 when moved -> 1.0 after trail_duration)
    let elapsed = max(pp.time - pp.cursor_change_time, 0.0);
    let progress = clamp(elapsed / trail_duration, 0.0, 1.0);
    let time_fade = 1.0 - progress;

    // The burning front recedes smoothly from h = 1.0 down to h = 0.0
    let burn_front = 1.0 - pow(progress, 0.75);

    // Trail intensity along the bridge
    var tail_fade = 0.0;
    if (is_valid_trail && burn_front > 0.001) {
        tail_fade = clamp((burn_front - h) / max(burn_front, 0.01), 0.0, 1.0) * time_fade;
    }

    // Flame Palette: Hot White/Yellow -> Blazing Orange -> Crimson Ember
    let flame_head   = vec4<f32>(1.0, 0.95, 0.45, 1.0);
    let flame_mid    = vec4<f32>(1.0, 0.45, 0.05, 1.0);
    let flame_tail   = vec4<f32>(0.85, 0.10, 0.00, 1.0);
    let blaze_color  = mix(flame_head, mix(flame_mid, flame_tail, h), clamp(h * 1.3, 0.0, 1.0));

    // 1. Inside actual text cursor: keep text readable with a soft warm tint
    if (dist_head <= 0.0) {
        return mix(base_color, flame_head, 0.22);
    }

    // 2. Solid fiery beam inside the motion trail
    if (dist_trail <= 0.0 && tail_fade > 0.01) {
        let core_opacity = tail_fade * 0.75;
        return mix(base_color, blaze_color, core_opacity);
    }

    // 3. Radiant Outer Flame Glow (exponential bloom)
    let pulse = (sin(pp.time * 8.0) * 0.5 + 0.5) * 0.2 + 0.8;

    let head_glow = exp(-max(dist_head, 0.0) / 12.0) * pulse * 0.35;
    let trail_glow = exp(-max(dist_trail, 0.0) / 18.0) * tail_fade * 0.90;

    let total_glow = clamp(max(head_glow, trail_glow), 0.0, 1.0);
    let glow_color = mix(flame_head, blaze_color, clamp(h, 0.0, 1.0));

    return mix(base_color, glow_color, total_glow);
}

// -------------------------------------------------------------
// Fragment Entry Point
// -------------------------------------------------------------
@fragment
fn main(in: VertexOutput) -> @location(0) vec4<f32> {
    let base_color = textureSample(screen_texture, screen_sampler, in.uv);
    return compute_cursor_blaze(in.uv, base_color);
}


// -------------------------------------------------------------
// Main Post-Processing Fragment Shader
// -------------------------------------------------------------
@fragment
fn fs_postprocess(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {

    // 1. PERFECTLY SHARP BASE TEXT
    let base_color = textureSample(screen_texture, screen_sampler, uv);

    // 2. SOFT, WIDE AMBIENT GLOW
    let glow_sigma = 1.0;
    let glow_color = compute_glow(uv, glow_sigma);
    var final_color = base_color + (glow_color * 0.15);

    // 3. CURSOR BLAZE OVERLAY
    final_color = compute_cursor_blaze(uv, final_color);

    return final_color;
}
