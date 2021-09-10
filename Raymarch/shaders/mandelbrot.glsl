#version 330 core

uniform vec3 iResolution;
uniform float iTime;
uniform vec4 iMouse;
in vec2 texcoord;
layout(location = 0) out vec4 fragColor;

vec2 cpow( vec2 z, float n ) { float r = length( z ); float a = atan( z.y, z.x ); return pow( r, n )*vec2( cos(a*n), sin(a*n) ); }

vec3 drawFractal( float k, vec2 fragCoord){
	vec3 col = vec3(0.0);

	for( int m = 0; m < 2; m++ )
	for( int n = 0; n < 2; n++ ){
		vec2 o = vec2(float(m), float(n)) / float(2) - 0.5;
		vec2 p = (-iResolution.xy + 2.0*(fragCoord + o)) / iResolution.y;

		vec2 c = p * 1.25;

		const float threshold = 64.0;
		vec2 z = vec2(0.0);
		float it = 0.0;
		for(int i = 0; i < 100; i++){
			z = cpow(z, k) + c;
			if(dot(z,z) > threshold) break;
			it++;
		}

		vec3 tmp = vec3(0.0);
		if(it < 99.5 ){
			float sit = it - log2(log2(dot(z,z))/log2(threshold))/log2(k);
			tmp = 0.5 + 0.5 * cos( 3.0 + sit*0.075*k + vec3(0.0,0.6,1.0));
		}

		col += tmp;
	}

	col /= float(2*2);

	return col;
}

void main()
{
	float eps = 1.25/iResolution.y;
	vec2 p = (-iResolution.xy + 2.0*gl_FragCoord.xy)/iResolution.y;

	float time = 0;

	vec2 c = p * 1.25;
	float k = 2.0 + floor(time) + smoothstep(0.8, 1.0, fract(time));

	float m = pow(k, (1.0/(1.0-k)));
	float n = pow(k, (k/(1.0-k)));

	vec3 col = drawFractal(k, gl_FragCoord.xy);

	fragColor = vec4(col, 1.0);
};
