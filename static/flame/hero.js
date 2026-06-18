// Front-page hero: a full-bleed animated fractal flame (the Rust/wgpu chaos-game
// renderer compiled to wasm; genomes + palettes baked into the wasm).
//
// Loaded as an ES module by /js/main.js, which only reaches here when
// navigator.gpu exists. If there's still no usable adapter, or the engine
// errors, we call window.__flameFallback() — main.js's ORIGINAL composition
// (drifting lines + circles + a small WebGL fractal disc) — so low-power /
// non-WebGPU devices always get the old front page. Served verbatim from
// static/ (unminified).

function fallback(canvas, style) {
  if (canvas) canvas.remove();
  if (style) style.remove();
  if (typeof window.__flameFallback === 'function') window.__flameFallback();
}

async function start() {
  // navigator.gpu is present (main.js gated on it), but the API can exist with
  // no usable GPU/driver — verify an adapter before committing the canvas.
  let adapter;
  try { adapter = await navigator.gpu.requestAdapter({ powerPreference: 'high-performance' }); }
  catch { return fallback(); }
  if (!adapter) return fallback();

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

  const sizeCanvas = () => {
    // Cap render resolution: the chaos-game scatter + per-pixel tonemap is the
    // cost on weak iGPUs, and a Retina hero would otherwise render ~4x the pixels.
    // The canvas is CSS-stretched to fill the viewport, so it stays full-bleed —
    // modest softness for a big speedup. Matches the standalone web/index.html.
    const dpr = Math.min(window.devicePixelRatio || 1, 1.25);
    const maxDim = 1536;
    let w = window.innerWidth * dpr, h = window.innerHeight * dpr;
    const s = Math.min(1, maxDim / Math.max(w, h, 1));
    canvas.width = Math.max(1, Math.floor(w * s));
    canvas.height = Math.max(1, Math.floor(h * s));
  };
  sizeCanvas();
  window.addEventListener('resize', sizeCanvas);

  try {
    // cache-bust the wasm URL: Chrome caches the COMPILED module by URL, so a fresh
    // build isn't picked up without this. Resolve against import.meta.url (this
    // module's dir, /flame/) — a bare './' would resolve against the PAGE (/) → 404.
    const v = Date.now();
    const { default: init, run } = await import('./flame.js?v=' + v);
    await init({ module_or_path: new URL('flame_bg.wasm?v=' + v, import.meta.url) });
    await run('flame-bg');
  } catch (e) {
    console.error('[flame] WebGPU engine error, falling back to the classic front page:', e);
    fallback(canvas, style);
  }
}

start();
