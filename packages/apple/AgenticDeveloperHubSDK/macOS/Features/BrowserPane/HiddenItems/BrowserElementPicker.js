// The element picker for "Hide distracting items" (recipe
// workspace/browser/element-picker). It runs in the `adk-element-picker`
// content world, after vendor/finder.js has defined `__adkFinder` in that same
// world, so the page's scripts can neither see nor replace anything here.
//
// While active it outlines the element under the pointer, swallows the page's
// clicks, posts one `pick` message per click and a `cancel` message on Esc to
// the `adkitchenPicker` handler. `__adkPicker.pause()` / `.resume()` /
// `.stop()` are its controls; `stop` leaves the page as it found it.
//
// It runs in the main frame only: WebKit has no public way to evaluate in a
// frame that is already loaded, and a cross-origin frame is out of the main
// frame's reach. A frame's own events never reach the main frame, so while
// selecting every frame element is made transparent to the pointer: its
// clicks land in the main frame, are swallowed there, and pick the frame
// element itself, which is what an entry then hides.
(function () {
  'use strict';
  if (globalThis.__adkPicker) { return; }   // one picker per world

  const HANDLER = 'adkitchenPicker';
  const LABEL_LIMIT = 60;
  const FINDER_TIMEOUT_MS = 1000;

  // A class name that looks generated: three or more digits in a row, six or
  // more letters and digits only, a `-`/`_` followed by five or more hex
  // characters, or a `-`/`_` followed by five or more letters and digits that
  // mix both (CSS-in-JS hashes such as `css-1x2y3z`).
  const GENERATED = /\d{3,}|^[a-z0-9]{6,}$|[-_][a-f0-9]{5,}/i;
  const MIXED_SUFFIX = /[-_](?=[a-z]*\d)(?=\d*[a-z])[a-z0-9]{5,}$/i;
  function isStableClass(name) {
    return !GENERATED.test(name) && !MIXED_SUFFIX.test(name);
  }

  let paused = false;
  let current = null;

  const outline = document.createElement('div');
  const outlineStyle = {
    position: 'fixed', top: '0px', left: '0px', width: '0px', height: '0px',
    margin: '0px', padding: '0px', border: '2px solid rgb(10, 132, 255)',
    background: 'rgba(10, 132, 255, 0.15)', 'border-radius': '2px',
    'box-sizing': 'border-box', 'pointer-events': 'none', 'z-index': '2147483647',
    display: 'none',
  };
  for (const key of Object.keys(outlineStyle)) {
    outline.style.setProperty(key, outlineStyle[key], 'important');
  }

  function post(message) {
    try { window.webkit.messageHandlers[HANDLER].postMessage(message); } catch (e) {}
  }

  function elementOf(target) {
    if (!target) { return null; }
    if (target.nodeType === Node.ELEMENT_NODE) { return target; }
    return target.parentElement || null;
  }

  // Frames stop taking pointer events while selecting, so a click on an ad
  // served in a frame is swallowed here instead of following the ad's link.
  const frameShield = document.createElement('style');
  frameShield.textContent = 'iframe, frame { pointer-events: none !important; }';
  const FRAMES = 'iframe, frame';

  // The frame element drawn under the point, when the point is over one: a
  // frame that takes no pointer events is never an event's target, so the
  // hit lands on what lies beneath it, usually an ancestor. A frame inside
  // the hit element that covers the point is drawn over it, the later of
  // several the higher; an element over the frame is the hit itself.
  function frameAt(el, x, y) {
    if (typeof x !== 'number' || typeof y !== 'number') { return null; }
    let frames;
    try { frames = document.querySelectorAll(FRAMES); } catch (e) { return null; }
    for (let i = frames.length - 1; i >= 0; i -= 1) {
      const frame = frames[i];
      if (frame !== el && !el.contains(frame)) { continue; }
      const r = frame.getBoundingClientRect();
      if (x >= r.left && x < r.right && y >= r.top && y < r.bottom) { return frame; }
    }
    return null;
  }

  // The element an event is about: its target, or the frame element the
  // pointer is over.
  function pickedBy(event) {
    const el = elementOf(event.target);
    if (!el || el === outline) { return null; }
    return frameAt(el, event.clientX, event.clientY) || el;
  }

  function place() {
    if (paused || !current || !current.isConnected) {
      outline.style.setProperty('display', 'none', 'important');
      return;
    }
    const r = current.getBoundingClientRect();
    outline.style.setProperty('top', r.top + 'px', 'important');
    outline.style.setProperty('left', r.left + 'px', 'important');
    outline.style.setProperty('width', r.width + 'px', 'important');
    outline.style.setProperty('height', r.height + 'px', 'important');
    outline.style.setProperty('display', 'block', 'important');
    if (!outline.isConnected) { document.documentElement.appendChild(outline); }
  }

  // "This item": finder's shortest unique selector, accepted only when it
  // matches exactly the picked element and that element is not the page's
  // root: blank space beside a layout hits `<body>`, and saving it would
  // hide the whole page.
  function thisItemSelector(el) {
    if (el === document.documentElement || el === document.head || el === document.body) {
      return null;
    }
    try {
      const sel = globalThis.__adkFinder(el, { timeoutMs: FINDER_TIMEOUT_MS });
      const hits = document.querySelectorAll(sel);
      return hits.length === 1 && hits[0] === el ? sel : null;
    } catch (e) {
      return null;
    }
  }

  // The page's frame, never a "like it" selector: hiding one hides the page.
  const NEVER_LIKE_IT = new Set(['html', 'head', 'body', 'main']);

  // "All items like it": the tag and the stable class names, never the id.
  // A tag alone is never one: `div` or `p` would hide most of the site.
  function allLikeItSelector(el) {
    try {
      const tag = el.tagName.toLowerCase();
      if (NEVER_LIKE_IT.has(tag)) { return null; }
      const classes = Array.from(el.classList).filter(isStableClass);
      if (classes.length === 0) { return null; }
      return tag + classes.map((name) => '.' + CSS.escape(name)).join('');
    } catch (e) {
      return null;
    }
  }

  function count(selector) {
    try { return document.querySelectorAll(selector).length; } catch (e) { return 0; }
  }

  function labelFor(el) {
    const tag = el.tagName.toLowerCase();
    const visible = typeof el.innerText === 'string' ? el.innerText : (el.textContent || '');
    let text = visible.replace(/\s+/g, ' ').trim();
    if (!text) { text = (el.getAttribute('alt') || '').replace(/\s+/g, ' ').trim(); }
    if (!text) { text = (el.getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim(); }
    if (!text) { return tag; }
    return tag + ' "' + Array.from(text).slice(0, LABEL_LIMIT).join('') + '"';
  }

  function refFor(el) {
    const holder = el.closest('[data-adk-ref]');
    return holder ? holder.getAttribute('data-adk-ref') : null;
  }

  function candidateFor(el) {
    const thisItem = thisItemSelector(el);
    let allLikeIt = allLikeItSelector(el);
    let allLikeItCount = allLikeIt ? count(allLikeIt) : 0;
    // The same as This item, by text or by what it matches: no looser choice.
    if (!allLikeIt || allLikeIt === thisItem || allLikeItCount <= 1) {
      allLikeIt = null;
      allLikeItCount = 0;
    }
    return {
      kind: 'pick',
      thisItem: thisItem,
      allLikeIt: allLikeIt,
      allLikeItCount: allLikeItCount,
      pageElementCount: document.getElementsByTagName('*').length,
      label: labelFor(el),
      ref: refFor(el),
    };
  }

  function swallow(event) {
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
  }

  function onMove(event) {
    if (paused) { return; }
    const el = pickedBy(event);
    if (el && el !== current) {
      current = el;
      place();
    }
  }

  function onPress(event) {
    swallow(event);
  }

  function onClick(event) {
    swallow(event);
    if (paused) { return; }
    const el = pickedBy(event);
    if (!el) { return; }
    post(candidateFor(el));
  }

  function onKey(event) {
    if (paused || event.key !== 'Escape') { return; }
    swallow(event);
    post({
      kind: 'cancel', thisItem: null, allLikeIt: null, allLikeItCount: 0,
      pageElementCount: 0, label: '', ref: null,
    });
  }

  function onViewportChange() { place(); }

  const listeners = [
    ['mousemove', onMove], ['mouseover', onMove],
    ['pointerdown', onPress], ['pointerup', onPress],
    ['mousedown', onPress], ['mouseup', onPress],
    ['dblclick', onPress], ['auxclick', onPress],
    ['click', onClick], ['keydown', onKey],
    ['scroll', onViewportChange], ['resize', onViewportChange],
  ];
  for (const [type, fn] of listeners) {
    window.addEventListener(type, fn, { capture: true });
  }
  (document.head || document.documentElement).appendChild(frameShield);
  // Focus left in a frame would keep Esc there, out of this listener's reach.
  try {
    const focused = document.activeElement;
    if (focused && focused.matches(FRAMES)) { focused.blur(); }
  } catch (e) {}

  globalThis.__adkPicker = {
    pause() {
      paused = true;
      place();
    },
    resume() {
      paused = false;
      place();
    },
    stop() {
      for (const [type, fn] of listeners) {
        window.removeEventListener(type, fn, { capture: true });
      }
      outline.remove();
      frameShield.remove();
      current = null;
      paused = true;
      delete globalThis.__adkPicker;
    },
  };
})();
