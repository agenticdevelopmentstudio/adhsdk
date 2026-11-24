// BrowserSnapshot.js — the runtime behind BrowserAutomation, installed in a
// content world of its own (BrowserSnapshotRuntime.world), so the page's
// scripts can neither read the ref table nor replace these functions. The
// DOM is shared across worlds; `window` and element expandos are not.
// Installed once per document (version-checked); every call returns plain JSON.
(function () {
  // Bumping the version re-installs over an older copy: its refs go stale (as after any
  // walk) and its MutationObserver stays behind, unused. Both are harmless. Keep it equal
  // to BrowserSnapshotRuntime.version.
  if (window.__adkitchen && window.__adkitchen.version === 5) { return; }

  const refs = new Map();            // ref -> WeakRef<Element>
  window.__adkitchenRefs = refs;
  // A random six-digit base chosen once per document, advanced by one per
  // walk: short enough for a model to copy back without a slip, and
  // unlikely to repeat another document's (ref, generation) numbers.
  let generation = 100000 + Math.floor(Math.random() * 900000);
  let nextRef = 1;
  let mutationCount = 0;
  try {
    new MutationObserver(() => { mutationCount += 1; })
      .observe(document.documentElement || document,
        { childList: true, subtree: true, attributes: true, characterData: true });
  } catch (e) { /* leave the counter at 0 rather than fail the install */ }

  const LANDMARKS = { header: 'banner', nav: 'navigation', main: 'main', footer: 'contentinfo',
    aside: 'complementary', form: 'form', section: 'region', article: 'article' };
  const TAGS = { a: 'link', button: 'button', select: 'combobox', textarea: 'textbox', option: 'option',
    img: 'img', table: 'table', thead: 'rowgroup', tbody: 'rowgroup', tfoot: 'rowgroup', tr: 'row',
    th: 'columnheader', td: 'cell', ul: 'list', ol: 'list', li: 'listitem', dialog: 'dialog',
    progress: 'progressbar', meter: 'meter', summary: 'button', details: 'group', iframe: 'iframe' };
  const INPUT_TYPES = { button: 'button', submit: 'button', reset: 'button', image: 'button',
    checkbox: 'checkbox', radio: 'radio', range: 'slider', number: 'spinbutton', search: 'searchbox',
    hidden: null };
  const VALID_ROLES = new Set(['alert','alertdialog','application','article','banner','button','cell',
    'checkbox','columnheader','combobox','complementary','contentinfo','dialog','document','feed','figure',
    'form','grid','gridcell','group','heading','img','link','list','listbox','listitem','main','menu',
    'menubar','menuitem','menuitemcheckbox','menuitemradio','navigation','option','progressbar','radio',
    'radiogroup','region','row','rowgroup','rowheader','scrollbar','search','searchbox','separator','slider',
    'spinbutton','status','switch','tab','table','tablist','tabpanel','textbox','timer','toolbar','tooltip',
    'tree','treegrid','treeitem','presentation','none']);
  const collapse = (s) => (s || '').replace(/\s+/g, ' ').trim();

  function roleOf(el) {
    const explicit = collapse(el.getAttribute('role') || '').split(' ')[0];
    if (explicit && VALID_ROLES.has(explicit)) { return explicit === 'none' ? 'presentation' : explicit; }
    const tag = el.tagName.toLowerCase();
    if (tag === 'a') { return el.hasAttribute('href') ? 'link' : null; }
    if (tag === 'input') {
      const type = (el.getAttribute('type') || 'text').toLowerCase();
      if (type in INPUT_TYPES) { return INPUT_TYPES[type]; }
      return 'textbox';
    }
    if (/^h[1-6]$/.test(tag)) { return 'heading'; }
    if (tag in LANDMARKS) { return LANDMARKS[tag]; }
    if (tag in TAGS) { return TAGS[tag]; }
    if (el.isContentEditable && el.getAttribute('contenteditable') !== null) { return 'textbox'; }
    return null;
  }

  function isHiddenUncached(el) {
    const tag = el.tagName.toLowerCase();
    if (tag === 'script' || tag === 'style' || tag === 'noscript' || tag === 'template' || tag === 'head') { return true; }
    if (el.hidden || el.getAttribute('aria-hidden') === 'true') { return true; }
    if (tag === 'input' && (el.getAttribute('type') || '').toLowerCase() === 'hidden') { return true; }
    if (tag === 'img' && el.getAttribute('alt') === '') { return true; }
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden') { return true; }
    if (tag !== 'option' && el.children.length === 0) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 && r.height === 0 && !collapse(el.textContent)) { return true; }
    }
    return false;
  }

  // An element that already holds a live ref in this table keeps it, so a
  // walk that keeps the refs (`beginWalk(true)`) hands out the same refs the
  // agent's last snapshot did.
  function assignRef(el) {
    const prior = el.__adkitchenRef;
    if (prior) {
      const held = refs.get(prior);
      if (held && held.deref() === el) { return prior; }
    }
    const ref = 'e' + (nextRef++);
    refs.set(ref, new WeakRef(el));
    el.__adkitchenRef = ref;
    return ref;
  }

  // A scope is a ref from the table, never a CSS selector: a selector would
  // let a caller probe the page past the agent's view (an excluded element's
  // attributes, character by character) by telling a match from none.
  function resolveScope(scope) {
    if (typeof scope !== 'string' || !scope) { return null; }
    const held = refs.get(scope);
    if (!held) { return null; }
    const el = held.deref();
    return (el && el.isConnected && !isWithheld(el)) ? el : null;
  }

  // The elements the last agent walk withheld (its agent list and hidden
  // rules), set by the walker. A ref handed out before an element joined the
  // agent list resolves to nothing once a walk has seen it excluded.
  let withheld = new WeakSet();
  function setWithheld(elements) {
    withheld = new WeakSet();
    for (const el of elements || []) { withheld.add(el); }
  }
  function isWithheld(el) {
    for (let at = el; at; at = at.parentElement) {
      if (withheld.has(at)) { return true; }
    }
    return false;
  }

  // Every ref stale at once: the agent list changed, so a ref the agent
  // holds may now name an element it may no longer be shown.
  function invalidate() {
    generation += 1;
    refs.clear();
    nextRef = 1;
    return true;
  }

  function resolve(ref, gen) {
    if (gen !== generation) { return { error: 'stale' }; }
    const held = refs.get(ref);
    if (!held) { return { error: 'unknown' }; }
    const el = held.deref();
    if (!el || !el.isConnected || isWithheld(el)) { return { error: 'stale' }; }
    return { el: el };
  }

  function focusedLandmark() {
    let el = document.activeElement;
    while (el && el !== document.body) {
      const role = roleOf(el);
      if (role === 'form' || (role && Object.values(LANDMARKS).includes(role)) || el.tagName.toLowerCase() === 'dialog') {
        const ref = el.__adkitchenRef;
        const held = ref ? refs.get(ref) : null;
        return (held && held.deref() === el) ? ref : null;
      }
      el = el.parentElement;
    }
    return null;
  }

  function withElement(ref, gen, fn) {
    const r = resolve(ref, gen);
    if (r.error) { return { error: r.error }; }
    try { return { ok: fn(r.el) }; } catch (e) { return { error: 'script: ' + (e && e.message ? e.message : String(e)) }; }
  }

  function centre(el) {
    const r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }

  function mouse(el, type, extra) {
    const c = centre(el);
    const init = Object.assign({ bubbles: true, cancelable: true, composed: true, clientX: c.x, clientY: c.y, view: window }, extra || {});
    el.dispatchEvent(new MouseEvent(type, init));
  }

  function click(ref, gen) {
    return withElement(ref, gen, (el) => {
      el.scrollIntoView({ block: 'center', inline: 'center' });
      if (el.tagName.toLowerCase() === 'option') {
        const select = el.closest('select');
        if (select) { select.value = el.value; el.selected = true; select.dispatchEvent(new Event('input', { bubbles: true })); select.dispatchEvent(new Event('change', { bubbles: true })); }
        return true;
      }
      if (el.tagName.toLowerCase() === 'a' && el.getAttribute('target') === '_blank') { el.removeAttribute('target'); }
      mouse(el, 'pointerdown'); mouse(el, 'mousedown');
      if (typeof el.focus === 'function') { el.focus(); }
      mouse(el, 'pointerup'); mouse(el, 'mouseup');
      el.click();
      return true;
    });
  }

  const KEY_CODES = { Enter: 13, Escape: 27, Tab: 9, Backspace: 8, Delete: 46, ArrowUp: 38, ArrowDown: 40, ArrowLeft: 37, ArrowRight: 39, Home: 36, End: 35, PageUp: 33, PageDown: 34, ' ': 32 };

  // Input types whose value the browser sanitizes on every write: "19." is
  // not a number and "2026-10" is not a date, so a value typed key by key
  // collapses to "" part-way through. These get the whole text in one write.
  const SANITIZED_INPUTS = new Set(['number', 'date', 'time', 'datetime-local', 'month', 'week']);

  function inputType(el) {
    return el.tagName.toLowerCase() === 'input' ? (el.getAttribute('type') || 'text').toLowerCase() : null;
  }

  function keyInit(key, mods) {
    const letter = key.length === 1 && /[a-z]/i.test(key);
    const digit = key.length === 1 && /[0-9]/.test(key);
    // keyCode is the key's own code for letters, digits and the named keys;
    // punctuation has none. Its character code would name another key: '&'
    // is 38, ArrowUp, which an autocomplete widget swallows.
    const code = letter ? 'Key' + key.toUpperCase() : digit ? 'Digit' + key : key.length === 1 ? '' : key;
    const keyCode = KEY_CODES[key] || ((letter || digit) ? key.toUpperCase().charCodeAt(0) : 0);
    return { key: key, code: code, keyCode: keyCode,
      bubbles: true, cancelable: true, composed: true,
      metaKey: !!mods.meta, shiftKey: !!mods.shift, altKey: !!mods.alt, ctrlKey: !!mods.control };
  }

  // `insert` false sends the key events but leaves the value alone, for a
  // caller that writes the value itself.
  function sendKey(target, key, mods, insert) {
    const down = new KeyboardEvent('keydown', keyInit(key, mods));
    const prevented = !target.dispatchEvent(down);
    if (!prevented && key.length === 1 && !mods.meta && !mods.control) {
      target.dispatchEvent(new KeyboardEvent('keypress', keyInit(key, mods)));
      if (insert === false) {
        // The caller writes the value.
      } else if ('value' in target && !target.readOnly) {
        // The prototype setter, not the instance one: React's value tracker
        // overrides the instance setter and drops the following input event
        // when the value it tracked already matches.
        setNativeValue(target, target.value + key);
        target.dispatchEvent(new InputEvent('input', { bubbles: true, data: key, inputType: 'insertText' }));
      } else if (target.isContentEditable) {
        document.execCommand('insertText', false, key);
      }
    }
    target.dispatchEvent(new KeyboardEvent('keyup', keyInit(key, mods)));
    return !prevented;
  }

  // What type and fill may write into: a textbox, a textarea or a
  // contenteditable. A select, checkbox, radio, slider, color input or button
  // has a `value` too, and writing it wrecks the control without a word: a
  // label written into a select deselects every option, "75" typed after a
  // range's 50 is 507. Those have tools of their own, which the sentence names.
  function refuseUnlessEditable(el, verb) {
    const tag = el.tagName.toLowerCase();
    const refuse = (what, hint) => { throw new Error(what + ' cannot be ' + verb + (hint ? '; use ' + hint : '')); };
    if (tag === 'select') { refuse('a select', 'browser_select'); }
    if (tag === 'input') {
      const kind = inputType(el);
      if (kind === 'checkbox' || kind === 'radio') { refuse('a ' + kind, 'browser_click'); }
      if (kind === 'button' || kind === 'submit' || kind === 'reset' || kind === 'image') { refuse('a button', 'browser_click'); }
      if (kind === 'range' || kind === 'color' || kind === 'file' || kind === 'hidden') { refuse('a ' + kind + ' input', null); }
    }
    if (tag === 'input' || tag === 'textarea') {
      if (el.disabled) { refuse('a disabled field', null); }
      if (el.readOnly) { refuse('a read-only field', null); }
      return;
    }
    if (el.isContentEditable) { return; }
    refuse('an element that is not a textbox, textarea or contenteditable', null);
  }

  function type(ref, gen, text, submit) {
    return withElement(ref, gen, (el) => {
      refuseUnlessEditable(el, 'typed into');
      el.focus();
      const wanted = String(text);
      const kind = inputType(el);
      if (SANITIZED_INPUTS.has(kind)) {
        for (const ch of wanted) { sendKey(el, ch, {}, false); }
        const expected = el.value + wanted;
        setNativeValue(el, expected);
        el.dispatchEvent(new InputEvent('input', { bubbles: true, data: wanted, inputType: 'insertText' }));
        if (el.value !== expected) {
          throw new Error('"' + expected + '" is not a valid ' + kind + ' value; the field holds "' + el.value + '"');
        }
      } else {
        for (const ch of wanted) { sendKey(el, ch, {}); }
      }
      if (submit) {
        if (sendKey(el, 'Enter', {}) && el.form && typeof el.form.requestSubmit === 'function') { el.form.requestSubmit(); }
      }
      return true;
    });
  }

  // Writes `value` through the element's prototype setter, past any setter a
  // framework installed on the instance itself. Walks the prototype chain
  // rather than naming HTMLInputElement, so an element with a `value` of
  // another kind (output, li, a custom element) gets its own setter.
  function setNativeValue(el, value) {
    for (let proto = Object.getPrototypeOf(el); proto; proto = Object.getPrototypeOf(proto)) {
      const descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
      if (descriptor && descriptor.set) { descriptor.set.call(el, value); return; }
    }
    el.value = value;
  }

  function fill(ref, gen, value) {
    return withElement(ref, gen, (el) => {
      refuseUnlessEditable(el, 'filled');
      el.focus();
      if (el.isContentEditable && !('value' in el)) {
        document.execCommand('selectAll', false, null);
        document.execCommand('insertText', false, String(value));
        return true;
      }
      if (typeof el.select === 'function') { el.select(); }
      setNativeValue(el, String(value));
      el.dispatchEvent(new InputEvent('input', { bubbles: true, data: String(value), inputType: 'insertReplacementText' }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    });
  }

  // An option the agent list withholds is no option at all: choosing it by a
  // guessed label must fail exactly as a label that names nothing, or the
  // answer would confirm it exists. Setting the value selects the first
  // option holding it, which may be a withheld one sharing it, so the match
  // is selected by itself after the setter.
  function select(ref, gen, value) {
    return withElement(ref, gen, (el) => {
      const wanted = String(value);
      const options = Array.from(el.options || []).filter((o) => !isWithheld(o));
      const match = options.find((o) => o.value === wanted) || options.find((o) => collapse(o.textContent) === wanted);
      if (!match) { throw new Error('no option "' + wanted + '"'); }
      setNativeValue(el, match.value);
      if (!match.selected) { match.selected = true; }
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    });
  }

  function hover(ref, gen) {
    return withElement(ref, gen, (el) => {
      el.scrollIntoView({ block: 'center', inline: 'center' });
      for (const t of ['pointerover', 'mouseover', 'mouseenter', 'pointermove', 'mousemove']) {
        mouse(el, t, t.endsWith('enter') ? { bubbles: false } : {});
      }
      return true;
    });
  }

  // "Meta+Shift+ArrowDown", "Enter", "a"
  function pressKey(spec) {
    const parts = String(spec).split('+');
    const key = parts.pop();
    const mods = {};
    for (const p of parts) { mods[p.toLowerCase()] = true; }
    const target = document.activeElement || document.body;
    try { return { ok: sendKey(target, key === 'Space' ? ' ' : key, mods) }; }
    catch (e) { return { error: 'script: ' + e.message }; }
  }

  function scroll(ref, gen, direction, amount) {
    if (ref) { return withElement(ref, gen, (el) => { el.scrollIntoView({ block: 'center', inline: 'center' }); return true; }); }
    const px = typeof amount === 'number' ? amount : window.innerHeight * 0.8;
    const dx = direction === 'left' ? -px : direction === 'right' ? px : 0;
    const dy = direction === 'up' ? -px : direction === 'left' || direction === 'right' ? 0 : px;
    window.scrollBy(dx, dy);
    return { ok: true };
  }

  // `scroll` false measures the element where it is: a read-only caller
  // must not move the page.
  function rect(ref, gen, scroll) {
    return withElement(ref, gen, (el) => {
      if (scroll !== false) { el.scrollIntoView({ block: 'center', inline: 'center' }); }
      const r = el.getBoundingClientRect();
      return { x: r.left, y: r.top, width: r.width, height: r.height };
    });
  }

  function isVisible(ref, gen) {
    const r = resolve(ref, gen);
    if (r.error) { return false; }
    return !isHiddenUncached(r.el);   // never the snapshot memo: the page may have changed since
  }

  // The agent walker's hold on this table (AgentPage/AgentPageWalker.js),
  // the one thing that hands out refs: a snapshot walk advances the
  // generation and restarts the refs, and registers every element ref it
  // emits through `assignRef`, so click, type, fill, select and hover resolve
  // exactly the refs the agent page showed, and an element the agent's list
  // hides never has one. A walk that only reads
  // (text, find, wait_for, the focused element) passes `keep`: the table and
  // the generation stay as the last snapshot left them, so the agent's refs
  // stay valid, and elements new since then get fresh refs after the rest.
  function beginWalk(keep) {
    if (keep === true && refs.size > 0) { return generation; }
    generation += 1;
    refs.clear();
    nextRef = 1;
    return generation;
  }

  window.__adkitchen = {
    version: 5,
    mutations: () => mutationCount,
    focusedLandmark: focusedLandmark,
    resolve: resolve,
    generation: () => generation,
    click: click, type: type, fill: fill, select: select, hover: hover, pressKey: pressKey,
    scroll: scroll, rect: rect, isVisible: isVisible,
    beginWalk: beginWalk, assignRef: assignRef, resolveScope: resolveScope,
    setWithheld: setWithheld, invalidate: invalidate,
  };
})();
