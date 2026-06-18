// Dedicated module worker: runs the flame renderer OFF the main thread, drawing
// into an OffscreenCanvas transferred from the page (hero.js). wgpu's WebGPU
// backend detects the worker context and uses WorkerNavigator.gpu automatically.
// On no-WebGPU / any init error it posts {type:'fallback'} so the page can drop to
// the classic composition. resize/visibility messages are handled inside the wasm
// (run_offscreen adds its own 'message' listener); this shim only kicks off 'start'.
self.addEventListener('message', async (e) => {
  const d = e.data;
  if (!d || d.type !== 'start') return;
  const q = d.v ? '?v=' + d.v : '';
  try {
    const { default: init, run_offscreen } = await import('./flame.js' + q);
    await init({ module_or_path: new URL('flame_bg.wasm' + q, import.meta.url) });
    await run_offscreen(d.canvas);
  } catch (err) {
    console.error('[flame worker] init/run failed, falling back:', err);
    self.postMessage({ type: 'fallback' });
  }
});
