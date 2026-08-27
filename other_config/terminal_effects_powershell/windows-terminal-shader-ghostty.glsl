// CC0: Ghostty Shader (Top-Right / Seamless Background Blend / No Box Artifacts)

// ==========================================
//          CUSTOMIZATION SETTINGS
// ==========================================

#define WIDGET_SCALE 0.40
#define BG_COLOR_HSV vec3(0.33, 0.85, 0.025)
#define FG_COLOR_HSV vec3(0.55, 0.85, 0.85)

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

vec3 effect(vec2 p) {
  g_rot0 = ROT(0.1*TIME); 
  g_rot1 = ROT(0.123*TIME);

  float aa = 2.0/RESOLUTION.y;
  float d = df(p);
  
  const vec3 bcol0 = HSV2RGB(FG_COLOR_HSV);
  const vec3 bcol1 = HSV2RGB(BG_COLOR_HSV);
  
  // 1. Sharp flower petals
  float shape = smoothstep(aa, -aa, d - 0.001);
  
  // 2. Tight glow strictly clamped to petals (drops to absolute 0 beyond 0.025)
  float glow = pow(smoothstep(0.025, 0.0, max(0.0, d - 0.001)), 3.0); 
  
  vec3 col = bcol0 * shape;
  col += bcol1 * (glow * 2.0);
  
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / RESOLUTION.xy;
  vec4 termText = texture(iChannel0, uv); 

  float size = RESOLUTION.y * WIDGET_SCALE;
  
  // Coordinates relative to Top-Right corner
  float distX = RESOLUTION.x - fragCoord.x;
  float distY = RESOLUTION.y - fragCoord.y;
  
  // Centered normalized coordinates for the top-right widget area
  vec2 localCoord = vec2(size - distX, size - distY);
  vec2 p = -1.0 + 2.0 * (localCoord / size);
  
  // Circular distance from the center of the widget
  float radialDist = length(p);
  
  // 1. Early exit: Anything outside the circular reach gets raw terminal texture
  if (radialDist > 1.25 || distX < 0.0 || distY < 0.0) {
      fragColor = termText;
      return;
  }
  
  // 2. Render the fractal
  vec3 col = effect(p);
  
  // 3. Smooth circular vignette (NO square edges)
  float circularMask = smoothstep(1.1, 0.3, radialDist);
  col *= circularMask;
  
  // 4. DEADBAND FILTER: If there is no flower petal/glow here, output 100% raw terminal background
  if (max(col.r, max(col.g, col.b)) < 0.001) {
      fragColor = termText;
      return;
  }
  
  // 5. Tone-mapping & gamma
  col = aces_approx(col);
  col = sqrt(col);
  
  // 6. SCREEN BLENDING: Seamless addition over Ghostty's grey background
  vec3 outputColor = 1.0 - (1.0 - termText.rgb) * (1.0 - col);
  
  // 7. Ensure text over the flowers remains crisp
  float textLuma = dot(termText.rgb, vec3(0.299, 0.587, 0.114));
  float isText = smoothstep(0.25, 0.60, textLuma); 
  outputColor = mix(outputColor, termText.rgb, isText * 0.85);
  
  fragColor = vec4(outputColor, 1.0);
}
