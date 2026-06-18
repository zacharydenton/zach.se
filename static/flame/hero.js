// Front-page hero: a full-bleed animated fractal flame (the Rust/wgpu chaos-game
// renderer compiled to wasm; genomes + palettes baked in).
//
// Loaded as an ES module by /js/main.js, which only reaches here when navigator.gpu
// exists. Rendering path, in preference order:
//   1. WORKER + OffscreenCanvas  — renders OFF the main thread, so page activity
//      (scroll/layout/GC) can't stutter the flame and the flame's frame work +
//      shader compiles never jank the page.
//   2. MAIN-THREAD                — if OffscreenCanvas/Worker is unsupported.
//   3. classic composition        — window.__flameFallback() (main.js's drifting
//      lines/circles), if there's no usable GPU or the engine errors.
// Served verbatim from static/ (unminified).

function targetSize() {
  // Cap render resolution: the chaos-game scatter + per-pixel tonemap is the cost
  // on weak iGPUs, and a Retina hero would render ~4x the pixels. CSS stretches the
  // canvas to full-bleed, so this is modest softness for a big speedup. Matches the
  // standalone web/index.html.
  const dpr = Math.min(window.devicePixelRatio || 1, 1.25);
  const maxDim = 1536;
  let w = window.innerWidth * dpr, h = window.innerHeight * dpr;
  const s = Math.min(1, maxDim / Math.max(w, h, 1));
  return [Math.max(1, Math.floor(w * s)), Math.max(1, Math.floor(h * s))];
}

function mkCanvas() {
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
  return { canvas, style };
}

function fallback(canvas, style) {
  if (canvas) canvas.remove();
  if (style) style.remove();
  if (typeof window.__flameFallback === 'function') window.__flameFallback();
}

// --- 1. worker path: OffscreenCanvas rendered off the main thread ---------------
function startWorker(canvas, style) {
  const [w, h] = targetSize();
  canvas.width = w;
  canvas.height = h; // set the buffer BEFORE transfer (can't after)
  let off;
  try {
    off = canvas.transferControlToOffscreen();
  } catch (e) {
    return startMainThread(canvas, style); // transfer unsupported → main thread
  }

  // cache-bust the worker + its wasm so a fresh build is picked up (Chrome caches
  // the compiled module by URL); the worker forwards `v` to flame.js + flame_bg.wasm.
  const v = Date.now();
  const worker = new Worker(new URL('./flame-worker.js?v=' + v, import.meta.url), { type: 'module' });
  worker.addEventListener('message', (e) => {
    if (e.data && e.data.type === 'fallback') {
      worker.terminate();
      fallback(canvas, style);
    }
  });
  worker.addEventListener('error', (e) => {
    console.error('[flame] worker error, falling back:', e.message || e);
    worker.terminate();
    fallback(canvas, style);
  });
  worker.postMessage({ type: 'start', canvas: off, w, h, v }, [off]);

  // the worker can't read the DOM — forward resize + tab-visibility as messages
  window.addEventListener('resize', () => {
    const [w, h] = targetSize();
    worker.postMessage({ type: 'resize', w, h });
  });
  document.addEventListener('visibilitychange', () =>
    worker.postMessage({ type: 'visible', hidden: document.hidden }));
}

// --- 2. main-thread path (no OffscreenCanvas/Worker) ----------------------------
async function startMainThread(canvas, style) {
  // navigator.gpu is present (main.js gated on it), but the API can exist with no
  // usable GPU — verify an adapter before committing.
  let adapter;
  try { adapter = await navigator.gpu.requestAdapter({ powerPreference: 'high-performance' }); }
  catch { return fallback(canvas, style); }
  if (!adapter) return fallback(canvas, style);

  const sizeCanvas = () => { const [w, h] = targetSize(); canvas.width = w; canvas.height = h; };
  sizeCanvas();
  window.addEventListener('resize', sizeCanvas);

  try {
    const v = Date.now();
    const { default: init, run } = await import('./flame.js?v=' + v);
    await init({ module_or_path: new URL('flame_bg.wasm?v=' + v, import.meta.url) });
    await run('flame-bg');
  } catch (e) {
    console.error('[flame] engine error, falling back:', e);
    fallback(canvas, style);
  }
}

function start() {
  const { canvas, style } = mkCanvas();
  const canWorker =
    typeof Worker !== 'undefined' &&
    typeof OffscreenCanvas !== 'undefined' &&
    typeof canvas.transferControlToOffscreen === 'function';
  if (canWorker) startWorker(canvas, style);
  else startMainThread(canvas, style);
}

start();
