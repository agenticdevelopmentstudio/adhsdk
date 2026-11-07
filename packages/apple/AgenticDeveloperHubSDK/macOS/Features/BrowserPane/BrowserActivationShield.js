/* adk-activation-shield */
// Makes the page see a focused, visible document whatever the window is doing
// (spec section 6). Injected at document start, in the page world, in every
// frame, so its capturing listeners are registered before any page script's.
// Also evaluated once, immediately, when the shield goes up over a page that
// is already showing (Pause Events, spec section 7): then it shields the
// window it runs in and every same-origin frame below it, which are already
// loaded and will not see the document-start copy until they reload.
// Best-effort: a determined page can detect the shim.
(function () {
  'use strict';

  // Where a shielded window keeps the function that takes the shim off
  // again. Its presence also says "already shielded", so a second run over
  // the same document (the immediate run after the document-start one) adds
  // nothing twice. Not enumerable, but a page that looks can find it; the
  // shim is detectable anyway.
  var RESTORE = '__adkActivationShield';

  function hasFocus() { return true; }

  // Swallowed before any page listener runs: these say the window or the
  // document changed state, which is exactly what the shield hides.
  function swallow(event) { event.stopImmediatePropagation(); }

  function shield(w) {
    if (Object.prototype.hasOwnProperty.call(w, RESTORE)) { return; }
    var doc = w.document;
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

    try {
      Object.defineProperty(w, RESTORE, {
        configurable: true,
        enumerable: false,
        writable: false,
        value: function () {
          undo.forEach(function (step) { step(); });
          delete w[RESTORE];
        }
      });
    } catch (e) { /* the shim stays until the next load, as it always could */ }
  }

  // This window, then every frame below it the script can reach. A
  // cross-origin frame throws on the first property read and is skipped:
  // its own document-start copy covers it from its next load.
  function visit(w) {
    try { shield(w); } catch (e) { return; }
    var count = 0;
    try { count = w.frames.length; } catch (e) { return; }
    for (var i = 0; i < count; i += 1) {
      try { visit(w.frames[i]); } catch (e) { /* cross-origin */ }
    }
  }

  visit(window);
})();
