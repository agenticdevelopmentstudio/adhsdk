// The element picker for "Hide distracting items" (recipe
// workspace/browser/element-picker). It runs in the `adk-element-picker`
// content world, after vendor/finder.js has defined `__adkFinder` and
// BrowserPickCandidates.js `__adkPickCandidates` in that same world, so the
// page's scripts can neither see nor replace anything here.
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
  const candidates = globalThis.__adkPickCandidates;
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
    post(candidates.candidateFor(el));
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
