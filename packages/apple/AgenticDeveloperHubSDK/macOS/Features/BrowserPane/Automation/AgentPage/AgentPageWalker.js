// AgentPageWalker.js — the page side of the agent's one gatekeeper (recipe
// workspace/browser/agent-page-builder). It runs in the automation content
// world (BrowserSnapshotRuntime.world), after BrowserSnapshot.js (whose ref
// table and generation it shares, so every ref it emits is one click, type,
// fill, select and hover resolve) and vendor/finder.js (`__adkFinder`, for the
// selector each node records).
//
// `__adkAgentWalk({ allowlist, excludeSelectors, scopeRef, interactiveOnly,
// maxDepth, timeoutMs, keepRefs, hideImages })` returns a JSON string: the
// `AgentWalkerPayload` (`{url, title, generation, warnings, root}`)
// AgentPageBuilder re-validates, `{"error": "timeout"}` when the walk outlives
// `timeoutMs` (default 1500), or `{"error": "agent-list"}` when an agent-list
// selector cannot be evaluated (fail closed: nothing is shown).
//
// It never visits a node — nor anything beneath it — that is hidden (computed
// display none, computed visibility hidden, the `hidden` attribute,
// `aria-hidden="true"`, and the legacy snapshot's other hidden rules) or that
// an agent-list selector matches. It emits only the allowlist's kinds, and on
// each only the allowlist's attributes. The tree's shape follows the legacy
// snapshot walk (BrowserSnapshot.js `build`), so the snapshot tool's output
// stays what it was for the same page.
(function () {
  'use strict';
  const VERSION = 7;
  if (globalThis.__adkAgentWalkVersion === VERSION && typeof globalThis.__adkAgentWalk === 'function') { return; }

  const DEFAULT_TIMEOUT_MS = 1500;
  // One finder call's budget. A node finder cannot place in time records the
  // structural path instead, so one hard element cannot spend the whole walk.
  const FINDER_TIMEOUT_MS = 25;
  // Finder's share of the whole walk's budget. Once finder has spent it,
  // every later node records the structural path, which costs one step past
  // its parent's (structuralPaths); a large page then still finishes where
  // today's snapshot does. Selectors never decide what is excluded (the agent list
  // is evaluated before the walk), so the cheaper path strips nothing less.
  const FINDER_SHARE = 1 / 3;
  const TIMED_OUT = { timedOut: true };

  const LANDMARK_TAGS = { header: 'banner', nav: 'navigation', main: 'main', footer: 'contentinfo',
    aside: 'complementary', form: 'form', section: 'region', article: 'article' };
  const TAG_KINDS = { button: 'button', summary: 'button', select: 'select', textarea: 'textArea',
    option: 'option', img: 'image', table: 'table', thead: 'rowGroup', tbody: 'rowGroup',
    tfoot: 'rowGroup', tr: 'row', th: 'columnHeader', td: 'cell', ul: 'list',
    ol: 'list', li: 'listItem', p: 'paragraph', label: 'label' };
  const INPUT_KINDS = { button: 'button', submit: 'button', reset: 'button', image: 'button',
    checkbox: 'checkbox', radio: 'radio' };
  // Explicit ARIA roles, as the legacy snapshot accepted them.
  const VALID_ROLES = new Set(['alert','alertdialog','application','article','banner','button','cell',
    'checkbox','columnheader','combobox','complementary','contentinfo','dialog','document','feed','figure',
    'form','grid','gridcell','group','heading','img','link','list','listbox','listitem','main','menu',
    'menubar','menuitem','menuitemcheckbox','menuitemradio','navigation','option','progressbar','radio',
    'radiogroup','region','row','rowgroup','rowheader','scrollbar','search','searchbox','separator','slider',
    'spinbutton','status','switch','tab','table','tablist','tabpanel','textbox','timer','toolbar','tooltip',
    'tree','treegrid','treeitem','presentation','none']);
  const LANDMARK_ROLES = new Set(['main', 'navigation', 'banner', 'contentinfo', 'complementary', 'search',
    'form', 'region', 'article']);
  const ROLE_KINDS = { link: 'link', button: 'button', tab: 'button', menuitem: 'button', treeitem: 'button',
    checkbox: 'checkbox', switch: 'checkbox', menuitemcheckbox: 'checkbox', radio: 'radio',
    menuitemradio: 'radio', textbox: 'textField', searchbox: 'textField', spinbutton: 'textField',
    slider: 'textField', combobox: 'select', listbox: 'select', option: 'option', heading: 'heading',
    list: 'list', listitem: 'listItem', table: 'table', grid: 'grid', treegrid: 'treeGrid', row: 'row',
    rowgroup: 'rowGroup', cell: 'cell', gridcell: 'gridCell', columnheader: 'columnHeader',
    rowheader: 'rowHeader', img: 'image' };
  // The `type` a role-only text field carries, so the snapshot prints the
  // role the legacy walk printed (AgentSnapshotMapper reads `type`); a
  // non-input slider or spinbutton also sends its `aria-valuenow` as value.
  const ROLE_TYPES = { searchbox: 'search', spinbutton: 'number', slider: 'range' };
  // Kinds the snapshot treats as generic: collapsed into one text line, or
  // flattened into their parent.
  const GENERIC_KINDS = new Set(['paragraph', 'label']);
  const NAME_FROM_CONTENT = new Set(['button', 'link', 'heading', 'cell', 'gridCell', 'columnHeader',
    'rowHeader', 'option']);
  // Roles the legacy walk named from content whose kind is not: they keep
  // that name when folded into checkbox and radio.
  const CONTENT_NAMED_ROLES = new Set(['switch', 'menuitemcheckbox', 'menuitemradio']);
  const CONTROLS = new Set(['textField', 'textArea', 'select', 'checkbox', 'radio']);
  const CONTROL_TAGS = new Set(['input', 'select', 'textarea', 'button']);
  // Elements whose contents are never page content an agent reads.
  const SKIPPED_TAGS = new Set(['script', 'style', 'noscript', 'template', 'head', 'iframe', 'frame',
    'object', 'embed']);

  const collapse = (s) => (s || '').replace(/\s+/g, ' ').trim();
  // Whitespace runs collapsed but the edges kept: a text node's leading or
  // trailing space is the boundary `innerText` reads between it and the
  // next piece (`Buy <b>now</b>` is "Buy now"), so text nodes carry it and
  // the builder joins the pieces before collapsing and concealing once.
  const squash = (s) => (s || '').replace(/\s+/g, ' ');
  // The line structure `innerText` keeps: a `<br>` and a block box's edges
  // are a line break, and a preformatted text node keeps its own newlines;
  // every other whitespace run is one space. A break is '\n' in the text
  // the walker emits. AgentPageBuilder keeps it for the page's text (one
  // line per break) and every other rendering collapses it to a space.
  const BREAK = '\n';
  const lineSquash = (s) => (s || '').replace(/[^\S\n]+/g, ' ').replace(/\s*\n\s*/g, BREAK);

  // A structural-selector function for one walk: `pathOf(el)` is
  // `html > body > div:nth-of-type(2) > …`. It is stored as a hide-from-agent
  // entry, so it must keep naming the same element when the Kitchen's own
  // document-start <style> elements (Hide Images, the hidden-items sheet)
  // come and go under <html>: `body` is the only body and takes no index,
  // and every other step counts only siblings of its own kind
  // (`:nth-of-type`), so an inserted <style> shifts nothing.
  //
  // Each parent's children are counted once, and each element's path is
  // kept for its descendants to extend, so a walk spends linear time on
  // paths however wide a container is: a list of thousands of rows would
  // otherwise rescan its siblings for every row and outlive the budget.
  function structuralPaths() {
    const paths = new Map();
    const indexes = new Map();
    function indexIn(el) {
      if (!indexes.has(el)) {
        const counts = new Map();
        for (const sibling of el.parentElement.children) {
          const key = sibling.namespaceURI + ' ' + sibling.localName;
          const n = (counts.get(key) || 0) + 1;
          counts.set(key, n);
          indexes.set(sibling, n);
        }
      }
      return indexes.get(el);
    }
    function step(el) {
      if (el === document.documentElement) { return 'html'; }
      const name = CSS.escape(el.localName);
      if (el === document.body || !el.parentElement) { return name; }
      return name + ':nth-of-type(' + indexIn(el) + ')';
    }
    return function pathOf(el) {
      const pending = [];
      let path = '';
      for (let at = el; at && at.nodeType === Node.ELEMENT_NODE; at = at.parentElement) {
        if (paths.has(at)) { path = paths.get(at); break; }
        pending.push(at);
        if (at === document.documentElement) { break; }
      }
      for (let i = pending.length - 1; i >= 0; i -= 1) {
        path = path ? path + ' > ' + step(pending[i]) : step(pending[i]);
        paths.set(pending[i], path);
      }
      return path;
    };
  }

  function walk(args) {
    const options = args || {};
    const kitchen = window.__adkitchen;
    if (!kitchen || typeof kitchen.beginWalk !== 'function') { return { error: 'runtime' }; }

    let allowlist = options.allowlist || {};
    if (typeof allowlist === 'string') { allowlist = JSON.parse(allowlist); }
    const allowedKinds = new Set(allowlist.kinds || []);
    const allowedAttributes = allowlist.attributes || {};
    const landmarkRoles = new Set(allowlist.landmarkRoles || []);
    const stateOrder = allowlist.states || [];

    const timeoutMs = (typeof options.timeoutMs === 'number' && options.timeoutMs >= 0)
      ? options.timeoutMs : DEFAULT_TIMEOUT_MS;
    const deadline = Date.now() + timeoutMs;
    const tick = () => { if (Date.now() >= deadline) { throw TIMED_OUT; } };
    let finderLeftMs = timeoutMs * FINDER_SHARE;
    const structuralPath = structuralPaths();

    // Every agent-list selector. One the document cannot evaluate would
    // exclude nothing, so the whole walk is refused rather than failing open.
    const warnings = [];
    const excluded = new Set();
    let selectors = options.excludeSelectors || [];
    if (typeof selectors === 'string') { selectors = JSON.parse(selectors); }
    for (const selector of selectors) {
      if (typeof selector !== 'string' || !selector.trim()) { continue; }
      try {
        document.querySelectorAll(selector).forEach((el) => excluded.add(el));
      } catch (e) {
        return { error: 'agent-list' };
      }
    }
    // Images under Hide Images are never visited, so they spend no ref.
    const hideImages = options.hideImages === true;

    const hiddenMemo = new Map(), classMemo = new Map(), descendantMemo = new Map();
    const displayMemo = new Map(), preMemo = new Map();

    function isHiddenUncached(el) {
      if (excluded.has(el)) { return true; }
      const tag = el.tagName.toLowerCase();
      if (SKIPPED_TAGS.has(tag)) { return true; }
      if (hideImages && (tag === 'img' || collapse(el.getAttribute('role') || '').split(' ')[0] === 'img')) {
        return true;
      }
      if (el.hidden || el.hasAttribute('hidden') || el.getAttribute('aria-hidden') === 'true') { return true; }
      if (tag === 'input' && (el.getAttribute('type') || '').toLowerCase() === 'hidden') { return true; }
      if (tag === 'img' && el.getAttribute('alt') === '') { return true; }
      const style = window.getComputedStyle(el);
      displayMemo.set(el, style.display);
      if (style.display === 'none' || style.visibility === 'hidden') { return true; }
      if (tag !== 'option' && el.children.length === 0) {
        const r = el.getBoundingClientRect();
        if (r.width === 0 && r.height === 0 && !collapse(el.textContent)) { return true; }
      }
      return false;
    }

    function displayOf(el) {
      if (!displayMemo.has(el)) { displayMemo.set(el, window.getComputedStyle(el).display); }
      return displayMemo.get(el);
    }

    // What an element's edges contribute to the text around it, as
    // `innerText` reads them: a break for a block box, a space for a table
    // cell, nothing for an inline box.
    function blockEdge(el) {
      const display = displayOf(el) || '';
      if (display === 'contents' || display.startsWith('inline') || display.startsWith('ruby')) { return ''; }
      return display === 'table-cell' ? ' ' : BREAK;
    }

    // A `<br>` that is shown: a line break, and nothing else. It is checked
    // before the hidden rules, whose empty-box rule would drop every one.
    function isLineBreak(el) { return el.tagName.toLowerCase() === 'br'; }
    function lineBreakShown(el) { return !excluded.has(el) && displayOf(el) !== 'none'; }

    function isPreformatted(el) {
      if (!el) { return false; }
      if (!preMemo.has(el)) {
        const style = window.getComputedStyle(el);
        const keep = style.whiteSpaceCollapse
          ? ['preserve', 'preserve-breaks', 'break-spaces'].includes(style.whiteSpaceCollapse)
          : /^(pre|pre-wrap|pre-line|break-spaces)$/.test(style.whiteSpace || '');
        preMemo.set(el, keep);
      }
      return preMemo.get(el);
    }

    // A text node's text: its newlines kept when its element preserves them
    // (`<pre>`, `white-space: pre*`), every whitespace run one space otherwise.
    function textOf(node) {
      const raw = node.textContent || '';
      if (/[\r\n]/.test(raw) && isPreformatted(node.parentElement)) {
        return lineSquash(raw.replace(/\r\n?/g, BREAK));
      }
      return squash(raw);
    }

    // Hidden, excluded, or of a kind the allowlist does not permit: never
    // visited, and nothing beneath it is either.
    function isSkipped(el) {
      if (!hiddenMemo.has(el)) {
        let skipped = isHiddenUncached(el);
        if (!skipped) {
          const info = classify(el);
          if (info && !allowedKinds.has(info.kind)) { skipped = true; }
        }
        hiddenMemo.set(el, skipped);
      }
      return hiddenMemo.get(el);
    }

    function isPasswordInput(el) {
      return el.tagName.toLowerCase() === 'input' && (el.getAttribute('type') || '').toLowerCase() === 'password';
    }

    // An element the legacy walk counted as interactive although nothing
    // else classifies it (legacy `isInteractive`): editable, its own or
    // inherited, is a text field; an `onclick` or a `tabindex` of 0 or more
    // is a button. Either keeps the ref today's snapshot gave it. `implicit`
    // lets `build` keep the children of one that wraps other content.
    function interactiveKind(el) {
      if (el.isContentEditable) { return { kind: 'textField', implicit: true }; }
      if (el.hasAttribute('onclick')) { return { kind: 'button', implicit: true }; }
      const tabindex = el.getAttribute('tabindex');
      if (tabindex !== null && Number(tabindex) >= 0) { return { kind: 'button', implicit: true }; }
      return null;
    }

    // `{kind, role?, type?, implicit?, contentNamed?}`, or null for an
    // element the snapshot treats as generic (flattened or collapsed).
    function classifyUncached(el) {
      const tag = el.tagName.toLowerCase();
      const explicit = collapse(el.getAttribute('role') || '').split(' ')[0];
      if (explicit && VALID_ROLES.has(explicit)) {
        if (explicit === 'none' || explicit === 'presentation') { return interactiveKind(el); }
        if (LANDMARK_ROLES.has(explicit)) { return { kind: 'landmark', role: explicit }; }
        const kind = ROLE_KINDS[explicit];
        if (!kind) { return interactiveKind(el); }
        if (kind === 'textField') {
          return { kind: kind, type: ROLE_TYPES[explicit] || (isPasswordInput(el) ? 'password' : undefined) };
        }
        return CONTENT_NAMED_ROLES.has(explicit) ? { kind: kind, contentNamed: true } : { kind: kind };
      }
      if (tag === 'a') { return el.hasAttribute('href') ? { kind: 'link' } : interactiveKind(el); }
      if (tag === 'input') {
        const type = (el.getAttribute('type') || 'text').toLowerCase();
        if (type in INPUT_KINDS) { return { kind: INPUT_KINDS[type] }; }
        return { kind: 'textField', type: type };
      }
      if (/^h[1-6]$/.test(tag)) { return { kind: 'heading' }; }
      if (tag in LANDMARK_TAGS) { return { kind: 'landmark', role: LANDMARK_TAGS[tag] }; }
      if (tag in TAG_KINDS) {
        const kind = TAG_KINDS[tag];
        return GENERIC_KINDS.has(kind) ? (interactiveKind(el) || { kind: kind }) : { kind: kind };
      }
      return interactiveKind(el);
    }

    function classify(el) {
      if (!classMemo.has(el)) { classMemo.set(el, classifyUncached(el)); }
      return classMemo.get(el);
    }

    function isGeneric(info) { return info === null || GENERIC_KINDS.has(info.kind); }

    function hasNonGenericDescendant(el) {
      if (descendantMemo.has(el)) { return descendantMemo.get(el); }
      let found = false;
      for (const child of el.children) {
        if (isSkipped(child)) { continue; }
        if (!isGeneric(classify(child)) || hasNonGenericDescendant(child)) { found = true; break; }
      }
      descendantMemo.set(el, found);
      return found;
    }

    // The text an element shows, skipping everything hidden or excluded
    // beneath it (where `textContent` would include it), collapsed — or,
    // with `keepEdges`, squashed with its boundary spaces kept.
    function visibleText(el, skipControls, keepEdges) {
      const parts = [];
      (function gather(node) {
        for (const child of node.childNodes) {
          if (child.nodeType === Node.TEXT_NODE) {
            parts.push(textOf(child));
          } else if (child.nodeType === Node.ELEMENT_NODE) {
            tick();
            if (isLineBreak(child)) {
              if (lineBreakShown(child)) { parts.push(BREAK); }
              continue;
            }
            if (isSkipped(child)) { continue; }
            if (skipControls && CONTROL_TAGS.has(child.tagName.toLowerCase())) { continue; }
            const edge = blockEdge(child);
            parts.push(edge);
            gather(child);
            parts.push(edge);
          }
        }
      })(el);
      const text = lineSquash(parts.join(''));
      return keepEdges ? text : text.trim();
    }

    // The legacy name's first sources: `aria-labelledby`'s targets (only the
    // ones an agent may see), then `aria-label`.
    function ariaName(el) {
      const ids = el.getAttribute('aria-labelledby');
      if (ids) {
        const text = ids.split(/\s+/).map((id) => (id ? document.getElementById(id) : null))
          .filter((target) => target && !isSkipped(target) && !hasSkippedAncestor(target))
          .map((target) => collapse(visibleText(target, false))).filter(Boolean).join(' ').trim();
        if (text) { return text; }
      }
      return collapse(el.getAttribute('aria-label') || '');
    }

    function labelsText(el) {
      if (!el.labels || !el.labels.length) { return ''; }
      return Array.from(el.labels)
        .filter((label) => !isSkipped(label) && !hasSkippedAncestor(label))
        .map((label) => collapse(visibleText(label, true))).filter(Boolean).join(' ');
    }

    function hasSkippedAncestor(el) {
      for (let at = el.parentElement; at && at !== document.documentElement; at = at.parentElement) {
        if (isSkipped(at)) { return true; }
      }
      return false;
    }

    function statesOf(el) {
      const states = new Set();
      const aria = (n) => el.getAttribute(n);
      if (el.checked === true || aria('aria-checked') === 'true') { states.add('checked'); }
      if (el.disabled === true || aria('aria-disabled') === 'true') { states.add('disabled'); }
      const openDetails = el.tagName.toLowerCase() === 'details' && el.open;
      if (aria('aria-expanded') === 'true' || openDetails) { states.add('expanded'); }
      if (el.selected === true || aria('aria-selected') === 'true') { states.add('selected'); }
      if (aria('aria-pressed') === 'true') { states.add('pressed'); }
      if (el.required === true || aria('aria-required') === 'true') { states.add('required'); }
      return stateOrder.filter((s) => states.has(s)).join(' ');
    }

    // A select's value is its first selected option the agent may see: a
    // withheld option (on the agent list, hidden, or in a withheld optgroup)
    // never reaches the agent through its select's `value`.
    function selectValue(el) {
      for (const option of Array.from(el.selectedOptions || [])) {
        let withheld = false;
        for (let at = option; at && at !== el; at = at.parentElement) {
          if (isHiddenUncached(at)) { withheld = true; break; }
        }
        if (!withheld) { return option.value ? option.value : null; }
      }
      return null;
    }

    // The legacy snapshot's value rule; never a password's.
    function valueOf(el, explicitRole) {
      const tag = el.tagName.toLowerCase();
      if (tag === 'input') {
        const type = (el.getAttribute('type') || 'text').toLowerCase();
        const valueless = ['password', 'checkbox', 'radio', 'button', 'submit', 'reset', 'image', 'file'];
        if (valueless.includes(type)) { return null; }
        return el.value ? el.value : null;
      }
      if (tag === 'select') { return selectValue(el); }
      if (tag === 'textarea') { return el.value ? el.value : null; }
      if (explicitRole === 'slider' || explicitRole === 'spinbutton') {
        return el.getAttribute('aria-valuenow') || null;
      }
      return null;
    }

    // Finder's selector while finder's share of the budget lasts, then the
    // structural path, which names exactly this element too.
    function selectorOf(el) {
      if (typeof globalThis.__adkFinder === 'function' && finderLeftMs >= 1) {
        const started = Date.now();
        try {
          const budget = Math.max(1, Math.min(FINDER_TIMEOUT_MS, finderLeftMs, deadline - started));
          return globalThis.__adkFinder(el, { timeoutMs: budget });
        } catch (e) {
          /* the structural path below */
        } finally {
          finderLeftMs -= Date.now() - started;
        }
      }
      return structuralPath(el);
    }

    let nextText = 1;
    function textNode(text) { return { ref: 't' + (nextText++), kind: 'text', text: text }; }

    // A generic node (a paragraph or label that is not interactive) prints in
    // the snapshot as text with no reference, as the legacy walk printed it,
    // so it takes a walk-local reference like a text piece and never spends
    // one of the page's element numbers: the references the tree does print
    // stay numbered as the legacy walk numbered them.
    let nextGeneric = 1;
    function refFor(el, kind) {
      return GENERIC_KINDS.has(kind) ? 'g' + (nextGeneric++) : kitchen.assignRef(el);
    }

    function permits(kind, name) {
      const names = allowedAttributes[kind];
      return Array.isArray(names) && names.includes(name);
    }

    function elementNode(el, info) {
      const node = { ref: refFor(el, info.kind), kind: info.kind, selector: selectorOf(el) };
      const attrs = {};
      const put = (name, value) => {
        if (value === null || value === undefined) { return; }
        const text = String(value);
        if (text && permits(info.kind, name)) { attrs[name] = text; }
      };
      // An element's own label text names a control; on anything else the
      // legacy walk named it by that text too, so it rides as `aria-label`.
      let name = ariaName(el);
      if (CONTROLS.has(info.kind)) {
        const labels = labelsText(el);
        if (labels) { node.text = labels; }
      } else if (!name) {
        name = labelsText(el);
      }
      put('aria-label', name);
      for (const attr of ['alt', 'title', 'placeholder', 'name']) {
        const v = el.getAttribute(attr);
        if (v && collapse(v)) { put(attr, collapse(v)); }
      }
      if (info.kind === 'textField' && info.type) { put('type', info.type); }
      if (info.kind === 'link') { put('href', el.getAttribute('href')); }
      if (info.kind === 'heading') {
        const m = /^h([1-6])$/.exec(el.tagName.toLowerCase());
        const aria = Number(el.getAttribute('aria-level'));
        put('level', m ? m[1] : (Number.isInteger(aria) && aria >= 1 ? String(aria) : '2'));
      }
      if (info.kind === 'landmark' && landmarkRoles.has(info.role)) { attrs.role = info.role; }
      const states = statesOf(el);
      if (states) { attrs.states = states; }
      if (Object.keys(attrs).length) { node.attrs = attrs; }
      if (info.kind === 'textField' || info.kind === 'textArea' || info.kind === 'select') {
        const explicit = collapse(el.getAttribute('role') || '').split(' ')[0];
        const value = isPasswordInput(el) ? null : valueOf(el, explicit);
        if (value !== null) { node.value = value; }
      }
      return node;
    }

    // Appends what `el` contributes to its parent: nothing, one node, one
    // text node, or (a generic element) its children's contributions.
    // `depthLeft` counts DOM levels as the legacy walk did; null is unlimited.
    function build(el, depthLeft, out) {
      tick();
      if (isLineBreak(el)) {
        if (lineBreakShown(el)) { out.push(textNode(BREAK)); }
        return;
      }
      if (isSkipped(el)) { return; }
      const info = classify(el);

      if (isGeneric(info)) {
        // A flattened block (a `div`) still ends a line where it ends.
        const edge = info ? '' : blockEdge(el);
        if (!hasNonGenericDescendant(el)) {
          const text = visibleText(el, false, !info);
          if (!collapse(text)) { return; }
          if (info) {
            const node = elementNode(el, info);
            node.text = text;
            out.push(node);
          } else {
            out.push(textNode(edge + text + edge));
          }
          return;
        }
        if (info) {
          const node = elementNode(el, info);
          node.children = [];
          childrenOf(el, depthLeft, node.children);
          out.push(node);
        } else {
          if (edge === BREAK) { out.push(textNode(BREAK)); }
          childrenOf(el, depthLeft, out);
          if (edge === BREAK) { out.push(textNode(BREAK)); }
        }
        return;
      }

      const node = elementNode(el, info);
      const named = node.attrs && (node.attrs['aria-label'] || node.attrs.alt || node.attrs.title
        || node.attrs.placeholder);
      // An implicit button (a clickable card, say) that holds links or
      // controls keeps them as children, as the legacy walk did.
      const fromContent = (NAME_FROM_CONTENT.has(info.kind) || info.contentNamed === true)
        && !(info.implicit && hasNonGenericDescendant(el));
      if (fromContent && !named) {
        // Named by its contents, which the snapshot then does not show: the
        // whole visible text rides as the node's own, whatever the depth.
        const text = visibleText(el, false);
        if (text) { node.text = text; }
        out.push(node);
        return;
      }
      if (depthLeft !== 0) {
        node.children = [];
        childrenOf(el, depthLeft, node.children);
      }
      out.push(node);
    }

    function childrenOf(el, depthLeft, out) {
      const next = depthLeft === null ? null : depthLeft - 1;
      if (next === -1) { return; }
      const start = out.length;
      const isSpace = (node) => node && node.kind === 'text' && node.text === ' ';
      for (const child of el.childNodes) {
        if (child.nodeType === Node.TEXT_NODE) {
          // Squashed, not trimmed. A whitespace-only node is kept as one
          // space between two contributions, never leading or doubled.
          const text = textOf(child);
          if (text === ' ') {
            if (out.length > start && !isSpace(out[out.length - 1])) { out.push(textNode(text)); }
          } else if (text) {
            out.push(textNode(text));
          }
        } else if (child.nodeType === Node.ELEMENT_NODE) {
          build(child, next, out);
        }
      }
      if (out.length > start && isSpace(out[out.length - 1])) { out.pop(); }
    }

    // A scope inside anything hidden or excluded is answered exactly as a
    // ref that names nothing: the whole page. Two different answers would
    // tell the agent whether a withheld element exists.
    function scopeIsWithheld(el) {
      for (let at = el; at && at !== document.documentElement; at = at.parentElement) {
        if (at.nodeType === Node.ELEMENT_NODE && isHiddenUncached(at)) { return true; }
      }
      return false;
    }

    // The page root itself withheld (an agent-list entry of `html` or
    // `body`, or a hidden body): the walk starts beneath body, so it must
    // say so here, or that entry would withhold nothing. The agent gets the
    // empty document, title included, whatever scope it asked for, and no
    // ref into the page resolves.
    const body = document.body;
    const pageWithheld = isHiddenUncached(document.documentElement) || (body !== null && isHiddenUncached(body));

    // The runtime refuses refs to withheld elements from here on (resolve
    // and resolveScope), whatever walk handed them out.
    if (typeof kitchen.setWithheld === 'function') {
      kitchen.setWithheld(pageWithheld ? [document.documentElement] : Array.from(excluded));
    }
    // Resolved before beginWalk resets the refs.
    const resolved = (options.scopeRef && !pageWithheld) ? kitchen.resolveScope(options.scopeRef) : null;
    const scopeEl = (resolved && !scopeIsWithheld(resolved)) ? resolved : null;
    // `keepRefs`: a reading walk that leaves the last snapshot's refs valid.
    const generation = kitchen.beginWalk(options.keepRefs === true);
    const depth = (typeof options.maxDepth === 'number' && options.maxDepth > 0) ? options.maxDepth : null;
    const title = pageWithheld ? '' : (document.title || '');
    const documentNode = (children) => ({ ref: 'doc', kind: 'document', children: children });

    let root;
    if (pageWithheld) {
      root = documentNode([]);
    } else if (scopeEl) {
      const built = [];
      build(scopeEl, depth, built);
      root = (built.length === 1 && built[0].kind !== 'text') ? built[0] : documentNode(built);
    } else {
      const children = [];
      if (body) { childrenOf(body, depth, children); }
      root = documentNode(children);
    }
    return { url: location.href, title: title, generation: generation, warnings: warnings, root: root };
  }

  globalThis.__adkAgentWalk = function (args) {
    try {
      return JSON.stringify(walk(args));
    } catch (e) {
      if (e === TIMED_OUT) { return JSON.stringify({ error: 'timeout' }); }
      return JSON.stringify({ error: 'script: ' + (e && e.message ? e.message : String(e)) });
    }
  };
  // The structural selector alone, for tests that pin its stability.
  globalThis.__adkAgentStructuralPath = function (el) { return structuralPaths()(el); };
  globalThis.__adkAgentWalkVersion = VERSION;
})();
