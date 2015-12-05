precision lowp float;
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

vec3 a(vec3 b) {
  vec4 c = vec4(1.0,2.0/3.0,1.0/3.0,3.0);
  vec3 d = abs(fract(b.xxx+c.xyz)*6.0-c.www);
  return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);
}

vec3 palette(float t) {
  return vec3(0.02, 0.5, 0.4) + vec3(0.8, 0.3, 0.1) * cos(6.28319 * (vec3(1.0, 2.0, 4.0) * t + vec3(0.8, 0.4, 0.65)));
}

void main(void) {
  vec2 e = ((gl_FragCoord.xy-resolution*0.5)/min(resolution.x,resolution.y))*20.0;
  float f = 0.0;
  float h=(7.296-0.01*mouse.x*0.2+0.0001*time) * 6.28319;
  float i=cos(h);
  float j=sin(h);
  vec2 k=vec2(i,-j);
  vec2 l=vec2(j,i);
  vec2 m=vec2(0,1.618);
  float n=3.516+0.01*mouse.y+0.0001*time;
  for(int o=0;o<120;o++){
    float p=dot(e,e);
    if(p>1.0){
      p=(1.0)/p;
      e.x=e.x*p;
      e.y=e.y*p;
    }
    f*=.99;
    f+=p;
    e=vec2(dot(e,k),dot(e,l))*n+m;
  }
  gl_FragColor = vec4(palette(fract(0.01 * time + f)), 1.0);
}
