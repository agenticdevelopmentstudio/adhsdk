/* adk-activation-shield */
// Makes the page see a focused, visible document whatever the window is doing
// (spec section 6). Injected at document start, in the page world, in every
// frame, so its capturing listeners are registered before any page script's.
// Best-effort: a determined page can detect the shim.
(function () {
  'use strict';

  function defineGetter(target, name, value) {
    try {
      Object.defineProperty(target, name, {
        configurable: true,
        enumerable: true,
        get: function () { return value; }
      });
    } catch (e) { /* a frozen or exotic target keeps its own answer */ }
  }

  function defineMethod(target, name, fn) {
    try {
      Object.defineProperty(target, name, {
        configurable: true,
        writable: true,
        enumerable: true,
        value: fn
      });
    } catch (e) { /* as above */ }
  }

  function hasFocus() { return true; }

  [Document.prototype, document].forEach(function (target) {
    defineMethod(target, 'hasFocus', hasFocus);
    defineGetter(target, 'visibilityState', 'visible');
    defineGetter(target, 'hidden', false);
  });

  // Swallowed before any page listener runs: these say the window or the
  // document changed state, which is exactly what the shield hides.
  function swallow(event) { event.stopImmediatePropagation(); }

  // Focus and blur also fire for elements inside the page; those still
  // work. Only the window- and document-level ones are hidden.
  function swallowWindowLevel(event) {
    if (event.target === window || event.target === document) {
      event.stopImmediatePropagation();
    }
  }

  [window, document].forEach(function (target) {
    ['visibilitychange', 'pagehide', 'freeze'].forEach(function (type) {
      target.addEventListener(type, swallow, true);
    });
    ['focus', 'blur'].forEach(function (type) {
      target.addEventListener(type, swallowWindowLevel, true);
    });
  });
})();
