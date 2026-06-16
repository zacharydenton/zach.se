// Front-page hero: a full-bleed animated fractal flame.
//
// On WebGPU-capable browsers it runs the real chaos-game flame renderer
// (Rust/wgpu compiled to wasm; the genomes + palettes are baked into the wasm).
// Everywhere else (phones, Firefox, Safari < 18) it falls back to the WebGL
// folding-fractal shader — so the page is never blank.
//
// Loaded as an ES module by /js/main.js (which is ES5 + minified and can't carry
// a dynamic import itself). Lives in static/ so it's served verbatim, unminified.

const canvas = document.createElement('canvas');
canvas.id = 'flame-bg';
canvas.style.cssText =
  'position:fixed;inset:0;width:100vw;height:100vh;z-index:-1;display:block;background:#000';
document.body.appendChild(canvas);

// keep header/nav legible over a bright flame
const style = document.createElement('style');
style.textContent =
  '.site-header .light,.site-footer .light{text-shadow:0 1px 10px rgba(0,0,0,.85),0 0 2px rgba(0,0,0,.6)}';
document.head.appendChild(style);

function sizeCanvas() {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = Math.max(1, Math.floor(window.innerWidth * dpr));
  canvas.height = Math.max(1, Math.floor(window.innerHeight * dpr));
}
sizeCanvas();
window.addEventListener('resize', sizeCanvas);

// ---- WebGL fallback: the folding-fractal shader, full-bleed -----------------
const FRAG = `precision mediump float;
uniform float time; uniform vec2 resolution;
vec3 pal(float f){return vec3(.02,.5,.4)+vec3(.8,.3,.1)*cos(6.28319*(vec3(1.,2.,4.)*f+vec3(.8,.4,.65)));}
void main(){
  vec2 g=((gl_FragCoord.xy-resolution*.5)/min(resolution.x,resolution.y))*20.;
  float h=0.; float i=(7.295+.0001*time)*6.28319;
  float j=cos(i),k=sin(i);
  vec2 l=vec2(j,-k), m=vec2(k,j), n=vec2(0.,1.618);
  float o=3.521+.0001*time;
  for(int p=0;p<800;p++){
    float q=dot(g,g);
    if(q>1.){q=1./q;g*=q;}
    h*=.99; h+=q;
    g=vec2(dot(g,l),dot(g,m))*o+n;
  }
  gl_FragColor=vec4(pal(fract(.01*time+h)),1.);
}`;
function startWebGL() {
  const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  if (!gl) return;
  const mk = (t, s) => { const sh = gl.createShader(t); gl.shaderSource(sh, s); gl.compileShader(sh); return sh; };
  const prog = gl.createProgram();
  gl.attachShader(prog, mk(gl.VERTEX_SHADER, 'attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}'));
  gl.attachShader(prog, mk(gl.FRAGMENT_SHADER, FRAG));
  gl.linkProgram(prog); gl.useProgram(prog);
  const loc = gl.getAttribLocation(prog, 'p');
  const buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
  const uTime = gl.getUniformLocation(prog, 'time');
  const uRes = gl.getUniformLocation(prog, 'resolution');
  const t0 = performance.now();
  (function frame() {
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.uniform1f(uTime, performance.now() - t0);
    gl.uniform2f(uRes, canvas.width, canvas.height);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    requestAnimationFrame(frame);
  })();
}

// ---- WebGPU flame (the real renderer) ---------------------------------------
async function startWebGPU() {
  if (!navigator.gpu) return false;
  let adapter;
  try { adapter = await navigator.gpu.requestAdapter({ powerPreference: 'high-performance' }); }
  catch { return false; }
  if (!adapter) return false;
  try {
    const { default: init, run } = await import('./flame.js');
    await init();
    await run('flame-bg');
    return true;
  } catch (e) {
    console.error('[flame] WebGPU engine error, falling back to WebGL:', e);
    return false;
  }
}

if (!(await startWebGPU())) startWebGL();
