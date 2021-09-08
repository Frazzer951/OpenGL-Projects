#version 330 core

uniform vec3 iResolution;
uniform float iTime;
uniform vec4 iMouse;
in vec2 texcoord;
layout(location = 0) out vec4 fragColor;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

float maxcomp(in vec2 p ) {
  return max(p.x, p.y);
}

float boxSDF(vec3 p, vec3 size) {
  vec3 d = abs(p) - (size / 2.0);
  float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
  float outsideDistance = length(max(d, 0.0));
  return insideDistance + outsideDistance;
}

float boxSDF( in vec2 p, in vec2 b )
{
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x ,d.y), 0.0);
}

float map(vec3 p){
  float d = boxSDF(p, vec3(1.0));
  vec3 res = vec3( d, 1.0, 0.0 );

  float s = 1.0;
  for(int m = 0; m < 3; m++){
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = abs(1.0 - 3.0 * abs(a));

    float da = maxcomp(abs(p.xy));
    float db = maxcomp(abs(p.yz));
    float dc = maxcomp(abs(p.zx));
    float c = (min(da, min(db ,dc)) - 1.0) / s;

    if(c > d){
      d = c;
      res = vec3( d, 0.2*da*db*dc, (1.0 + float(m)) / 4.0);
    }
  }

  return d;
}

/*
vec3 intersect(vec3 ro, vec3 rd){
  for(float t = 0.0; t < 10.0;){
    vec3 h = map(ro + rd * t);
    if( h.x < 0.001 )
      return vec3(t, h.yz);
    t += h;
  }
  return vec3(-1.0);
}
*/
float sceneSDF(vec3 samplePoint) {
  return map(samplePoint);
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
  float depth = start;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
    float dist = sceneSDF(eye + depth * marchingDirection);
    if (dist < EPSILON) {
      return depth;
    }
    depth += dist;
    if (depth >= end) {
      return end;
    }
  }
  return end;
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
  vec2 xy = fragCoord - size / 2.0;
  float z = size.y / tan(radians(fieldOfView) / 2.0);
  return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
  return normalize(vec3(
    sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
    sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
    sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
  ));
}

vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntensity) {
  vec3 N = estimateNormal(p);
  vec3 L = normalize(lightPos - p);
  vec3 V = normalize(eye - p);
  vec3 R = normalize(reflect(-L, N));

  float dotLN = dot(L, N);
  float dotRV = dot(R, V);

  if (dotLN < 0.0) {
    // Light not visible from this point on the surface
    return vec3(0.0, 0.0, 0.0);
  }

  if (dotRV < 0.0) {
    // Light reflection in opposite direction as viewer, apply only diffuse
    // component
    return lightIntensity * (k_d * dotLN);
  }
  return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
  const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
  vec3 color = ambientLight * k_a;

  vec3 light1Pos = vec3(4.0 * sin(iTime),
                        2.0,
                        4.0 * cos(iTime));
  vec3 light1Intensity = vec3(0.4, 0.4, 0.4);

  color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                light1Pos,
                                light1Intensity);

  vec3 light2Pos = vec3(2.0 * sin(0.37 * iTime),
                        2.0 * cos(0.37 * iTime),
                        2.0);
  vec3 light2Intensity = vec3(0.4, 0.4, 0.4);

  color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                light2Pos,
                                light2Intensity);
  return color;
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up){
  vec3 f = normalize(center - eye);
  vec3 s = normalize(cross(f, up));
  vec3 u = cross(s, f);
  return mat3(s, u, -f);
}

void main()
{
  //vec3 dir = rayDirection(45.0, iResolution.xy, fragCoord);
  vec3 viewDir = rayDirection(45.0, iResolution.xy, gl_FragCoord.xy);
  // vec3 eye = vec3(1.0, 1.0, 7.0);
  vec3 eye = vec3(8.0, 5.0 * sin(0.2 * iTime), 7.0);

  mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));

  //vec3 worldDir = viewDir;
  vec3 worldDir = viewToWorld * viewDir;

  float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);

  if (dist > MAX_DIST - EPSILON) {
    // Didn't hit anything
    fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    return;
  }

  // The closest point on the surface to the eyepoint along the view ray
  vec3 p = eye + dist * worldDir;

  vec3 K_a = (estimateNormal(p) + vec3(1.0)) / 2.0;
  vec3 K_d = K_a;
  vec3 K_s = vec3(1.0, 1.0, 1.0);
  float shininess = 10.0;

  vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);

  fragColor = vec4(color, 1.0);
}