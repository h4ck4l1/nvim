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

vec3 effect(vec2 p, vec2 pp) {
  g_rot0 = ROT(0.1*TIME); 
  g_rot1 = ROT(0.123*TIME);

  float aa = 2.0/RESOLUTION.y;
  float d = df(p);
  
  const vec3 bcol0 = HSV2RGB(FG_COLOR_HSV);
  const vec3 bcol1 = HSV2RGB(BG_COLOR_HSV);
  
  vec3 col = 0.1*bcol0;
  col += bcol1/sqrt(abs(d));
  col += bcol0*smoothstep(aa, -aa, (d-0.001));
  col *= smoothstep(1.5, 0.5, length(pp));
  
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 1. FIX Y-AXIS: Calculate distance from Top-Right 
  float distX = RESOLUTION.x - fragCoord.x; // Distance from right
  float distY = fragCoord.y;                // Distance from top (Y is inverted in your terminal)
  
  float size = RESOLUTION.y * WIDGET_SCALE;
  
  // 2. THE FIX: If outside the widget, abort shading entirely.
  // This prevents the shader from drawing a black box over your terminal text!
  if (distX > size || distY > size) {
      discard;
  }
  
  // 3. Setup local coordinates so the fractal doesn't stretch or break
  vec2 localCoord = vec2(size - distX, size - distY);
  vec2 localRes = vec2(size, size);
  
  vec2 q = localCoord / localRes;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  
  p.x *= localRes.x / localRes.y; 
  
  vec3 col = effect(p, pp);
  col = aces_approx(col);
  col = sqrt(col);
  
  // 4. Smoothly fade the boundary edges of the widget
  float edgeFade = 0.15 * size; 
  float alphaX = smoothstep(size, size - edgeFade, distX);
  float alphaY = smoothstep(size, size - edgeFade, distY);
  
  float luma = dot(col, vec3(0.299, 0.587, 0.114)); 
  float alpha = alphaX * alphaY * mix(luma * 1.5, 1.0, DARK_OPACITY);
  
  // 5. Blend the faded edges into the terminal background color
  vec3 finalColor = mix(TERMINAL_BG_COLOR, col, clamp(alpha, 0.0, 1.0));
  
  fragColor = vec4(finalColor, 1.0);
}
