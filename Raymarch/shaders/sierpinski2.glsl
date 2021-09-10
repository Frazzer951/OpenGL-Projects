#version 330 core

uniform vec3 iResolution;
uniform float iTime;
uniform vec4 iMouse;
in vec2 texcoord;
layout(location = 0) out vec4 fragColor;

// Sierpinski3 Triangle

//==============================================================================
const vec3 lightDirection = vec3(0.5, 0.5, -0.5);
const vec3 keyLightColor  = vec3(1.0, 1.0, 1.0);
const vec3 fillLightColor = vec3(0.0, 0.2, 0.4);
const vec3 backgroundColor = vec3(0.1, 0.1, 0.1);
const float cameraDistance = 9.0;
const float EPS = 0.001;
const int FRACTAL_ITERATIONS = 16;
const int RAY_MARCH_ITERATIONS = 150;
const vec3 N_EPS = vec3(EPS, 0.0, 0.0); // for normals
mat3 rotation;

float dPlane(vec3 p){
    return p.y;
}


//==============================================================================

float sierpinski3d(vec3 p)
{
  float scale = 1.8+cos(iTime)*0.18;
  float offset = 1.5;
  float x1,y1,z1;
  for(int n=0; n< FRACTAL_ITERATIONS; n++)
  {
        p.xy = (p.x+p.y < 0.0) ? -p.yx : p.xy;
    p.xz = (p.x+p.z < 0.0) ? -p.zx : p.xz;
    p.zy = (p.z+p.y < 0.0) ? -p.yz : p.zy;

    p = scale*p-offset*(scale-1.0);
  }

  return length(p) * pow(scale, -float(FRACTAL_ITERATIONS));
}


//==============================================================================
float dist(vec3 p, out float ao) {
  vec3 pp = p+vec3(1.0,2.11,0.0);
    p = rotation * p;
  ao = 1.0;

    vec3 Q = p;
  float res;
    res = dPlane(pp);

    // first do a shpere to put everything inside it
    {
    float radius = 5.2;
    float r = length(p) - radius;
    if (r > 5.0) { return r; }
  }

  float derivative = 1.0;
  for (int i = 0; i < FRACTAL_ITERATIONS; ++i) {

        ao *= 0.725;
    ao = min((ao + 0.075) * 4.1, 1.0);
    res = min(res,sierpinski3d(p));
        return res;

    }

  return 0.0;
}

float dist(vec3 p) {
  float ignore;
  return dist(p, ignore);
}


//==============================================================================

float shadow(vec3 o, vec3 r)
{
    float t = 0.0;
    float md = 1000.0;
    float lt = 0.0;
    for (int i = 0; i < 32; ++i) {
        vec3 pos = o + r * t;
        float d = dist(pos);
        md = min(md, 16.0*d/t);
        t += min(d, 0.1);
    }
    return clamp(md,0.0,1.0);
}



vec3 trace(vec2 coord) {
    vec3 color;

    float cameraAnimation = 0.75*(cos(iTime)+2.0);

  vec3 ro = vec3(2.0 * coord / iResolution.xy - 1.0, -cameraDistance);
  // aspect ratio
  ro.x *= iResolution.x / iResolution.y;
    vec3 rd = normalize(normalize(vec3(0.0, 1.0, 3.0) - ro) + (	vec3( ro.xy, 2.0 ) / cameraAnimation) );
  rd.y -=cos(0.1)*0.11;
    float t = 0.0;
  vec3 x;
  float d,s;
  bool hit = false;
  vec3 light = vec3(1.0,cos(iTime*0.25)*0.05+1.0,0.0);

  // marching
  for (int i = 0; i < RAY_MARCH_ITERATIONS; ++i) {
    x = ro + rd * t;
    d = dist(x);

    hit = (d < EPS);
    if (hit) { break; }
    t += d;
  }
  if (hit) {
        // Compute AO term
    float ao;
    dist(x, ao);

    // Back away from the surface a bit before computing the gradient
    x -= rd * N_EPS.x;

    // Accurate micro-normal
      vec3 n = normalize(
      vec3(d - dist(x - N_EPS.xyz),
             d - dist(x - N_EPS.yxz),
           d - dist(x - N_EPS.zyx)));

    // Broad scale normal to large shape
      vec3 n2 = normalize(
      vec3(d - dist(x - N_EPS.xyz * 50.0),
             d - dist(x - N_EPS.yxz * 50.0),
           d - dist(x - N_EPS.zyx * 50.0)));

        // shadows
        s = shadow(x, light);

        // blend
    n = normalize(n + n2 + normalize(x));

        ao *= s;
        // surface
        return ao * mix(fillLightColor, keyLightColor, ao * clamp(dot(lightDirection, n) + 0.5, 0.0, 1.0));

  }
    else
    {
    // if missed
        return backgroundColor * sqrt(length((coord / iResolution.xy - vec2(0.55, 0.55)) * 2.5));
  }
}


void main() {

    // Euler-angle rot
  float time = iTime*0.25;
  rotation    = mat3( cos(time), sin(time),	0.0,
                     -sin(time), cos(time),	0.0,
                      0.0,			 0.0,		    1.0) *
                mat3( cos(time), 0.0, 		  sin(time),
                      0.0, 		   1.0, 		  0.0,
                     -sin(time), 0.0, 		  cos(time));

    //4x-rotated grid SSAA for antialiasing
  vec3 color =
      (trace(gl_FragCoord.xy + vec2(-0.125, -0.375)) +
       trace(gl_FragCoord.xy + vec2(+0.375, -0.125)) +
       trace(gl_FragCoord.xy + vec2(+0.125, +0.375)) +
       trace(gl_FragCoord.xy + vec2(-0.375, +0.125))) / 4.0;

  // gamm correction
  color = sqrt(color);

    fragColor = vec4(color, 1.0);
}