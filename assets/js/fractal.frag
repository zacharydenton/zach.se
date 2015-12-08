precision lowp float;
uniform float time;
uniform vec2 resolution;

vec3 a(vec3 b) {
  vec4 c = vec4(1., 2. / 3., 1. / 3., 3.);
  vec3 d = abs(fract(b.xxx + c.xyz) * 6. - c.www);
  return b.z * mix(c.xxx, clamp(d - c.xxx, .0, 1.), b.y);
}

vec3 palette(float t) {
  return vec3(.02, .5, .4) + vec3(.8, .3, .1) * cos(6.28319 * (vec3(1., 2., 4.) * t + vec3(.8, .4, .65)));
}

void main(void) {
  vec2 e = ((gl_FragCoord.xy - resolution * .5) / min(resolution.x, resolution.y)) * 20.;
  float f = .0;
  float h = (7.295 + .0001 * time) * 6.28319;
  float i = cos(h);
  float j = sin(h);
  vec2 k = vec2(i, -j);
  vec2 l = vec2(j, i);
  vec2 m = vec2(0, 1.618);
  float n = 3.521 + .0001 * time;
  for (int o = 0; o < 120; o++) {
    float p = dot(e, e);
    if (p > 1.) {
      p = 1. / p;
      e *= p;
    }
    f *= .99;
    f += p;
    e = vec2(dot(e, k), dot(e, l)) * n + m;
  }
  gl_FragColor = vec4(palette(fract(.01 * time + f)), 1.);
}
