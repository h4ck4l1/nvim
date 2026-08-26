void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, uv);
    
    // Tint text to a retro terminal green with subtle scanlines
    float scanline = sin(uv.y * iResolution.y * 2.0) * 0.08;
    vec3 retroColor = terminalColor.rgb * vec3(0.2, 1.0, 0.3) - scanline;
    
    fragColor = vec4(retroColor, terminalColor.a);
}
