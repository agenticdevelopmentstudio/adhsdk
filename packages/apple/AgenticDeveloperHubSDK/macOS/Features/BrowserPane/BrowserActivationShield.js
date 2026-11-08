/* adk-activation-shield */
// Makes the page see a focused, visible document whatever the window is doing
// (spec section 6). Injected at document start, in the page world, in every
// frame, so its capturing listeners are registered before any page script's.
// Also evaluated once, immediately, when the shield goes up over a page that
// is already showing (Pause Events, spec section 7): then it shields the
// window it runs in and every same-origin frame below it, which are already
// loaded and will not see the document-start copy until they reload. The
// same text, with the mode set to lift, takes the shim off those frames when
// the shield comes down.
// Best-effort: a determined page can detect the shim.
//
// The two placeholders are replaced by BrowserActivationShield.swift before
// the text reaches a page: the mode, and the bytes of a token chosen once
// per web view.
//
// It must run in the page world: its getters replace what the page's own
// `document` answers, and in an isolated world they would change only that
// world's view. So the record it leaves on a window is reachable by the
// page, and is guarded by a handshake (ownRecord) rather than hidden.
(function () {
  'use strict';

  var MODE = '__ADK_SHIELD_MODE__';
  // The token's UTF-8 bytes. It never appears in the page as text and is
  // never handed to a page function: only digests of it are, keyed to a
  // fresh challenge, so no page can read it, link two sites by it, or call
  // the shim's lift.
  var TOKEN = __ADK_SHIELD_TOKEN_BYTES__;

  // Where a shielded window keeps the shim's record of the document it
  // shielded and how to take the shim off again. Not enumerable, but a page
  // that looks can find it; the shim is detectable anyway. Calling it gets
  // the page nothing without a key only the token's holder can compute.
  var RECORD = '__adkActivationShield';

  // The two directions of the handshake, so a caller's key is never a valid
  // answer and an answer is never a valid key.
  var CALLER = 1;
  var ANSWER = 2;

  var challenges = 0;

  // SHA-256 of the token's bytes, then `label`, then the challenge's
  // characters, as hex. Synchronous, because the shim must be in place
  // before any page script runs; `crypto.subtle` is asynchronous and absent
  // from insecure contexts. Typed arrays and local arithmetic only, so the
  // token's bytes pass through no method a page could have replaced.
  function digest(label, challenge) {
    var length = TOKEN.length + 1 + challenge.length;
    var padded = (((length + 8) >> 6) + 1) << 6;
    var bytes = new Uint8Array(padded);
    var i;
    for (i = 0; i < TOKEN.length; i += 1) { bytes[i] = TOKEN[i]; }
    bytes[TOKEN.length] = label;
    for (i = 0; i < challenge.length; i += 1) {
      bytes[TOKEN.length + 1 + i] = challenge.charCodeAt(i) & 0xff;
    }
    bytes[length] = 0x80;
    var bits = length * 8;
    bytes[padded - 4] = (bits >>> 24) & 0xff;
    bytes[padded - 3] = (bits >>> 16) & 0xff;
    bytes[padded - 2] = (bits >>> 8) & 0xff;
    bytes[padded - 1] = bits & 0xff;

    var k = new Int32Array([
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]);
    var h = new Int32Array([
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]);
    var w = new Int32Array(64);
    function ror(x, n) { return (x >>> n) | (x << (32 - n)); }
    for (var block = 0; block < padded; block += 64) {
      var t;
      for (t = 0; t < 16; t += 1) {
        var at = block + t * 4;
        w[t] = (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3];
      }
      for (t = 16; t < 64; t += 1) {
        var x = w[t - 15];
        var y = w[t - 2];
        var s0 = ror(x, 7) ^ ror(x, 18) ^ (x >>> 3);
        var s1 = ror(y, 17) ^ ror(y, 19) ^ (y >>> 10);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) | 0;
      }
      var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
      for (t = 0; t < 64; t += 1) {
        var t1 = (hh + (ror(e, 6) ^ ror(e, 11) ^ ror(e, 25)) + ((e & f) ^ (~e & g)) + k[t] + w[t]) | 0;
        var t2 = ((ror(a, 2) ^ ror(a, 13) ^ ror(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
        hh = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      h[0] = (h[0] + a) | 0; h[1] = (h[1] + b) | 0; h[2] = (h[2] + c) | 0; h[3] = (h[3] + d) | 0;
      h[4] = (h[4] + e) | 0; h[5] = (h[5] + f) | 0; h[6] = (h[6] + g) | 0; h[7] = (h[7] + hh) | 0;
    }
    var hex = '';
    for (i = 0; i < 8; i += 1) { hex += ('0000000' + (h[i] >>> 0).toString(16)).slice(-8); }
    return hex;
  }

  // The shim's own record on `w`, or null when there is none — including
  // when the value there is the page's own. The handshake runs both ways:
  // the record answers only a caller whose key proves it holds the token,
  // and the caller accepts only an answer that proves the same. A page that
  // defines the name first can neither make the shield skip its window nor
  // be handed a lift to run, and learns only a digest keyed to a fresh
  // challenge, never the token; a page that calls the real record gets null.
  function ownRecord(w) {
    var probe = w[RECORD];
    if (typeof probe !== 'function') { return null; }
    challenges += 1;
    var challenge = String(Math.random()).slice(2) + ':' + challenges;
    var answer = null;
    try { answer = probe(challenge, digest(CALLER, challenge)); } catch (e) { return null; }
    if (!answer || answer.proof !== digest(ANSWER, challenge)) { return null; }
    return answer;
  }

  function hasFocus() { return true; }

  // Swallowed before any page listener runs: these say the window or the
  // document changed state, which is exactly what the shield hides.
  function swallow(event) { event.stopImmediatePropagation(); }

  function shield(w) {
    var doc = w.document;
    var existing = ownRecord(w);
    // Shielded already: this document. The shim is per document, not per
    // window — a frame's first same-origin navigation away from its initial
    // about:blank keeps the Window and replaces the document — so a record
    // left by the previous document is lifted first and the new one
    // shielded, rather than taken for this one.
    if (existing && existing.doc === doc) { return; }
    if (existing) { existing.lift(); }

    var proto = w.Document.prototype;
    var undo = [];

    function remember(target, name) {
      var own = Object.getOwnPropertyDescriptor(target, name);
      undo.push(function () {
        try {
          if (own) {
            Object.defineProperty(target, name, own);
          } else {
            delete target[name];
          }
        } catch (e) { /* a target that refused the shim refuses this too */ }
      });
    }

    function defineGetter(target, name, value) {
      try {
        remember(target, name);
        Object.defineProperty(target, name, {
          configurable: true,
          enumerable: true,
          get: function () { return value; }
        });
      } catch (e) { /* a frozen or exotic target keeps its own answer */ }
    }

    function defineMethod(target, name, fn) {
      try {
        remember(target, name);
        Object.defineProperty(target, name, {
          configurable: true,
          writable: true,
          enumerable: true,
          value: fn
        });
      } catch (e) { /* as above */ }
    }

    [proto, doc].forEach(function (target) {
      defineMethod(target, 'hasFocus', hasFocus);
      defineGetter(target, 'visibilityState', 'visible');
      defineGetter(target, 'hidden', false);
    });

    // Focus and blur also fire for elements inside the page; those still
    // work. Only the window- and document-level ones are hidden.
    function swallowWindowLevel(event) {
      if (event.target === w || event.target === doc) {
        event.stopImmediatePropagation();
      }
    }

    [w, doc].forEach(function (target) {
      ['visibilitychange', 'pagehide', 'freeze'].forEach(function (type) {
        target.addEventListener(type, swallow, true);
        undo.push(function () { target.removeEventListener(type, swallow, true); });
      });
      ['focus', 'blur'].forEach(function (type) {
        target.addEventListener(type, swallowWindowLevel, true);
        undo.push(function () { target.removeEventListener(type, swallowWindowLevel, true); });
      });
    });

    var probe = function (challenge, key) {
      if (typeof challenge !== 'string' || typeof key !== 'string') { return null; }
      if (key !== digest(CALLER, challenge)) { return null; }
      return { proof: digest(ANSWER, challenge), doc: doc, lift: lift };
    };
    function lift() {
      undo.forEach(function (step) { step(); });
      undo = [];
      try {
        if (w[RECORD] === probe) { delete w[RECORD]; }
      } catch (e) { /* nothing left to take off */ }
    }

    try {
      Object.defineProperty(w, RECORD, {
        configurable: true,
        enumerable: false,
        writable: false,
        value: probe
      });
    } catch (e) { /* the shim stays until the next load, as it always could */ }
  }

  function unshield(w) {
    var record = ownRecord(w);
    if (record) { record.lift(); }
  }

  // This window, then every frame below it the script can reach. A
  // cross-origin frame throws on the first property read and is skipped:
  // its own document-start copy covers it from its next load.
  function visit(w, act) {
    try { act(w); } catch (e) { return; }
    var count = 0;
    try { count = w.frames.length; } catch (e) { return; }
    for (var i = 0; i < count; i += 1) {
      try { visit(w.frames[i], act); } catch (e) { /* cross-origin */ }
    }
  }

  visit(window, MODE === 'lift' ? unshield : shield);
})();
