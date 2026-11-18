// What a pick is: the selectors, label and ref of one element (recipe
// workspace/browser/element-picker). It runs in the `adk-element-picker`
// content world, after vendor/finder.js has defined `__adkFinder` there, and
// defines `__adkPickCandidates`, which two callers share: the element picker
// (BrowserElementPicker.js), for each click while selecting, and the page's
// context menu, for the element and the selected text under a right-click.
(function () {
  'use strict';
  if (globalThis.__adkPickCandidates) { return; }   // one copy per world

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

  // One `pick` message for `el`.
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

  // The page's selected text, whitespace collapsed; '' when nothing is
  // selected. A right-click on a word selects it, so this is the word.
  function selectedText() {
    try {
      const selection = window.getSelection();
      return selection ? selection.toString().replace(/\s+/g, ' ').trim() : '';
    } catch (e) {
      return '';
    }
  }

  globalThis.__adkPickCandidates = {
    candidateFor: candidateFor,
    selectedText: selectedText,
    // The element drawn at the viewport point (x, y), in CSS pixels, as a
    // pick, with the selected text beside it; null when nothing is there.
    at(x, y) {
      const el = document.elementFromPoint(x, y);
      if (!el) { return null; }
      const candidate = candidateFor(el);
      candidate.selectedText = selectedText();
      return candidate;
    },
  };
})();
