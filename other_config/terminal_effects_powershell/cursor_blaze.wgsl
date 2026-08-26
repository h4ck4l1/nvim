// -------------------------------------------------------------
// Cursor Blaze Helper Functions (Converted from GLSL)
// -------------------------------------------------------------
fn ease(x: f32) -> f32 {
    // The aggressive ease-out that makes the blaze look like a shooting star
    return pow(1.0 - x, 10.0);
}

fn sd_box(p: vec2<f32>, xy: vec2<f32>, b: vec2<f32>) -> f32 {
    let d = abs(p - xy) - b;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

fn compute_cursor_blaze(uv: vec2<f32>, base_color: vec4<f32>) -> vec4<f32> {
    // -----------------------------------------------------------------------
    // NOTE: Replace `cursor.pos` and `cursor.size` with the exact WGSL 
    // uniform names WezTerm exposes in PR 8076 for the cursor coordinates.
    // -----------------------------------------------------------------------
    let c_pos = cursor.pos;      
    let c_size = cursor.size;    
    
    // Defines how far back the trail goes
    let trail_length = 5.0; 
    let blaze_color = vec4<f32>(1.0, 0.5, 0.0, 1.0); // Neon Orange/Red blaze

    // Calculate distance from current pixel to the cursor
    let dist = sd_box(uv, c_pos, c_size);

    // We only want the trail to draw behind the cursor's movement path
    if (dist > 0.0 && dist < trail_length) {
        // Calculate how far along the trail this pixel is (0.0 to 1.0)
        let progress = dist / trail_length;
        
        // Apply the ease function so the head is bright and the tail sharply fades
        let alpha = ease(progress);

        // Mix the blaze color into the terminal background
        return mix(base_color, blaze_color, alpha * 0.8);
    }
    
    return base_color;
}
