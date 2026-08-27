// CC0: Another windows terminal shader
// FIXED: Y-axis inversion (Top-Right) & Text Visibility (Discard)

// ==========================================
//          CUSTOMIZATION SETTINGS
// ==========================================

#define WIDGET_SCALE 0.40
#define BG_COLOR_HSV vec3(0.33, 0.85, 0.025)
#define FG_COLOR_HSV vec3(0.55, 0.85, 0.85)
#define DARK_OPACITY 0.2

// The shader gently fades out at the edges. Change this color to match 
// your terminal's actual background theme so the fade looks seamless.
// Pure black = vec3(0.0), Pure white = vec3(1.0)
#define TERMINAL_BG_COLOR vec3(0.0, 0.0, 0.0)

// ==========================================

#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const mat2 rot0 = ROT(0.0);
mat2 g_rot0 = rot0;
mat2 g_rot1 = rot0;

vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

float apolloian(vec3 p, float s) {
  float scale = 1.0;
  for(int i=0; i < 5; ++i) {
    p = -1.0 + 2.0*fract(0.5*p+0.5);
    float r2 = dot(p,p);
    float k  = s/r2;
    p       *= k;
    scale   *= k;
  }
  
  vec3 ap = abs(p/scale);  
  float d = length(ap.xy);
  d = min(d, ap.z);

  return d;
}

float df(vec2 p) {
  float fz = mix(0.75, 1., smoothstep(-0.9, 0.9, cos(TAU*TIME/300.0)));
  float z = 1.55*fz;
  p /= z;
  vec3 p3 = vec3(p,0.1);
  p3.xz*=g_rot0;
  p3.yz*=g_rot1;
  float d = apolloian(p3, 1.0/fz);
  d *= z;
  return d;
}

// Changed to return vec4 so we can pass transparency (alpha) to mainImage!
vec4 effect(vec2 p, vec2 pp) {
  g_rot0 = ROT(0.1*TIME); 
  g_rot1 = ROT(0.123*TIME);

  float aa = 2.0/RESOLUTION.y;
  float d = df(p);
  
  const vec3 bcol0 = HSV2RGB(FG_COLOR_HSV);
  const vec3 bcol1 = HSV2RGB(BG_COLOR_HSV);
  
  // 1. THE SHAPE: This creates the solid, sharp "flowers" (1.0 inside, 0.0 outside)
  float shape = smoothstep(aa, -aa, (d - 0.001));
  
  // 2. THE GLOW: Replaced the infinite noise with a tight glow that stops completely
  // at a distance of 0.15. This removes the green background haze entirely!
  float glow = smoothstep(0.15, 0.0, abs(d)); 
  
  vec3 col = bcol0 * shape;           // Solid flower color
  col += (bcol1 * glow * 1.5);        // Subtle green edge glow around the flowers
  
  // Vignette effect for the edges of the widget
  float vignette = smoothstep(1.5, 0.5, length(pp));
  col *= vignette;
  
  // 3. TRANSPARENCY: Solid shapes are 100% opaque, glow is semi-transparent, empty space is 0%
  float alpha = clamp(shape + (glow * 0.8), 0.0, 1.0) * vignette;
  
  return vec4(col, alpha);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / RESOLUTION.xy;
  vec4 termText = texture(iChannel0, uv); 

  float distX = RESOLUTION.x - fragCoord.x;
  float distY = fragCoord.y;                
  
  float size = RESOLUTION.y * WIDGET_SCALE;
  
  if (distX > size || distY > size) {
      fragColor = termText;
      return;
  }
  
  vec2 localCoord = vec2(size - distX, size - distY);
  vec2 localRes = vec2(size, size);
  
  vec2 q = localCoord / localRes;
  vec2 p = -1. + 2. * q;
  vec2 p_copy = p;
  
  p.x *= localRes.x / localRes.y; 
  
  // 4. Get the fractal color AND its exact transparency mask
  vec4 fractalData = effect(p, p_copy);
  vec3 col = fractalData.rgb;
  float fractalAlpha = fractalData.a; 
  
  col = aces_approx(col);
  col = sqrt(col);
  
  // Fade the boundaries of the widget box
  float edgeFade = 0.15 * size; 
  float alphaX = smoothstep(size, size - edgeFade, distX);
  float alphaY = smoothstep(size, size - edgeFade, distY);
  
  // Combine all the transparencies together
  float finalAlpha = alphaX * alphaY * fractalAlpha;
  
  // 5. LAYER 1: Blend the fractal directly over the raw terminal background!
  // Where finalAlpha is 0 (the empty space), it shows your pure terminal background.
  vec3 outputColor = mix(termText.rgb, col, finalAlpha);
  
  // 6. LAYER 2: Ensure the text is written ON TOP of the flowers
  float textLuma = dot(termText.rgb, vec3(0.299, 0.587, 0.114));
  float isText = smoothstep(0.01, 0.08, textLuma); 
  
  outputColor = mix(outputColor, termText.rgb, isText);
  
  fragColor = vec4(outputColor, 1.0);
}
