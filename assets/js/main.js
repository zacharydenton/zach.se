"use strict";

// Front-page art: load the full-bleed fractal-flame hero. This file is run
// through classic uglifyjs (no ES6), so it can't carry the module's dynamic
// import() itself — it just injects /flame/hero.js (served verbatim from
// static/, an ES module) which runs the WebGPU flame with a WebGL fallback.
(function () {
    var s = document.createElement("script");
    s.type = "module";
    s.src = "/flame/hero.js";
    document.head.appendChild(s);
})();
