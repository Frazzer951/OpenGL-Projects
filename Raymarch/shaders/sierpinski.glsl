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

mat3 rotateX(float theta){
 float c = cos(theta);
 float s = sin(theta);

 return mat3(
  vec3(1, 0,  0),
  vec3(0, c, -s),
  vec3(0, s,  c)
 );
}

mat3 rotateY(float theta){
 float c = cos(theta);
 float s = sin(theta);

 return mat3(
  vec3( c, 0, s),
  vec3( 0, 1, 0),
  vec3(-s, 0, c)
 );
}

mat3 rotateZ(float theta){
 float c = cos(theta);
 float s = sin(theta);

 return mat3(
  vec3(c, -s, 0),
  vec3(s,  c, 0),
  vec3(0,  0, 1)
 );
}

float maxcomp( vec3 p ) {
  return max(p.x, max(p.y, p.z));
}

float intersectSDF(float distA, float distB) {
  return max(distA, distB);
}

float unionSDF(float distA, float distB) {
  return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
  return max(distA, -distB);
}

float sierpinski3d(vec3 p, int iteratrions)
{
  float scale = 2;
  float offset = 1.5;
  float x1,y1,z1;
  for(int n=0; n< iteratrions; n++)
  {
    p.xy = (p.x+p.y < 0.0) ? -p.yx : p.xy;
    p.xz = (p.x+p.z < 0.0) ? -p.zx : p.xz;
    p.zy = (p.z+p.y < 0.0) ? -p.yz : p.zy;

    p = scale*p-offset*(scale-1.0);
  }

  return length(p) * pow(scale, -float(iteratrions));
}

float sceneSDF(vec3 p) {
  return sierpinski3d(p, 60);
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
      break;
    }
  }
  return end;
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
  vec2 xy = fragCoord - size / 2.0;
  float z = size.y / tan(radians(fieldOfView) / 2.0);
  return normalize(vec3(xy, -z));
}

vec3 calcNormal(vec3 p) {
  vec3 small = vec3(EPSILON, 0.0, 0.0);

  float x = sceneSDF(vec3(p + small.xyy)) - sceneSDF(vec3(p - small.xyy));
  float y = sceneSDF(vec3(p + small.yxy)) - sceneSDF(vec3(p - small.yxy));
  float z = sceneSDF(vec3(p + small.yyx)) - sceneSDF(vec3(p - small.yyx));

  return normalize(vec3(x, y, z));
}

float calcSoftshadow( vec3 pos, vec3 dir, float start, float end, float k ){
  float res = 1.0;
  float ph = 1e20;

  for( float depth = start; depth<end; ){
    float dist = sceneSDF(pos + dir * depth);
    if( dist < EPSILON ) return 0.0;
    float y = dist * dist / (2.0 * ph);
    float d = sqrt(dist * dist - y * y);
    res = min( res, k * d / max(0.0, depth - y) );
    ph = dist;
    depth += dist;
  }
  return res;
}

float calcAO( vec3 pos, vec3 nor){
  float occ = 0.0;
  float sca = 1.0;
  for(int i = 0; i < 5; i++ ){
    float h = 0.001 + 0.15 * float(i) / 4.0;
    float d = sceneSDF( pos + h * nor);
    occ += (h - d) * sca;
    sca *= 0.95;
  }
  return clamp( 1.0 - 1.5 * occ, 0.0, 1.0);
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up){
  vec3 f = normalize(center - eye);
  vec3 s = normalize(cross(f, up));
  vec3 u = cross(s, f);
  return mat3(s, u, -f);
}

void main()
{
  vec3 viewDir = rayDirection(45.0, iResolution.xy, gl_FragCoord.xy);
  vec3 eye = vec3(8.0, 5.0 * sin(0.2 * iTime), 7.0);
  //vec3 eye = vec3(8.0, 5.0, 7.0);

  mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));

  vec3 worldDir = viewToWorld * viewDir;

  vec3 color = vec3(0.0);
  float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);

  if(dist > -0.5){

    vec3 pos = eye + dist * worldDir;
    vec3 nor = calcNormal(pos);

    // material
    vec3 mat = vec3(0.4, 0.8, 0.8);

    // key light
    vec3 lig = normalize( vec3(-0.1, 0.3, 0.6) );
    vec3 hal = normalize( lig - worldDir );
    float dif = clamp( dot( nor, lig ), 0.0, 1.0 ) * calcSoftshadow(pos, lig, 0.01, 3.0, 2);

    float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ), 16.0 ) *
                dif *
                (0.04 + 0.96 * pow( clamp( 1.0 + dot( hal, worldDir ), 0.0, 1.0), 5.0 ));

    color = mat * 4.0 * dif * vec3(1.0, 0.7, 0.5);
    color +=     12.0 * spe * vec3(1.0, 0.7, 0.5);

    // Ambient Light
    float occ = calcAO( pos, nor );
    float amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
    color += mat * amb * occ * vec3(0.0, 0.08, 0.1);

    // fog
    color *= exp( -0.0005 * dist * dist * dist );
  }

  color = pow( color, vec3(0.4545) );

  fragColor = vec4(color, 1.0);
}