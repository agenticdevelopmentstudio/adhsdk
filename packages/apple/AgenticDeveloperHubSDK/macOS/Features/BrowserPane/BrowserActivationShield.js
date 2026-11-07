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
// the text reaches a page: the mode, and a token chosen once per launch.
(function () {
  'use strict';

  var MODE = '__ADK_SHIELD_MODE__';
  var TOKEN = '__ADK_SHIELD_TOKEN__';

  // Where a shielded window keeps the shim's record of the document it
  // shielded and how to take the shim off again. Not enumerable, but a page
  // that looks can find it; the shim is detectable anyway.
  var RECORD = '__adkActivationShield';

  var challenges = 0;

  // The shim's own record on `w`, or null when there is none — including
  // when the value there is the page's own. The value is a function that
  // answers a fresh challenge with a proof only the token's holder can
  // compute, so a page that defines the name first can neither make the
  // shield skip its window nor be handed a lift to run; and the challenge,
  // not the token, is what such a page's function is called with.
  function ownRecord(w) {
    var probe = w[RECORD];
    if (typeof probe !== 'function') { return null; }
    challenges += 1;
    var challenge = String(Math.random()).slice(2) + ':' + challenges;
    var answer = null;
    try { answer = probe(challenge); } catch (e) { return null; }
    if (!answer || answer.proof !== challenge + '|' + TOKEN) { return null; }
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

    var probe = function (challenge) {
      return { proof: challenge + '|' + TOKEN, doc: doc, lift: lift };
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
