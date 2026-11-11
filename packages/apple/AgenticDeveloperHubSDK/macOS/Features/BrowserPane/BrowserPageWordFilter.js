/* adk-page-word-filter */
// Agent Privacy on the page itself: every real privacy word in the page's
// text is drawn as the word it is shown as, the way a private terminal shows
// it. Injected at document start in every frame, so the text is rewritten as
// the parser adds it, before the first paint shows it.
//
// It runs in an isolated world of its own, never the page world: the word
// list is the user's, and a page script that patched a built-in this script
// calls could otherwise read every pair. The DOM is shared between worlds, so
// what it writes is what the page draws.
//
// Matching ignores case, and a stand-in is written in the case of the word it
// replaces ("BLUEBIRD" -> "REDBIRD", "bluebird" -> "redbird").
//
// Rewritten: text nodes (not inside script, style, textarea or an editable
// region, where rewriting would change what a form sends or move the caret)
// and the title, alt, placeholder and aria-label attributes. The page's title
// is its <title> element's text node, rewritten as any other, so it is never
// substituted a second time; a script that sets document.title replaces that
// node, and the new one arrives as an added node.
// Open shadow roots are followed. A word split across elements, drawn on a
// canvas, or inside a closed shadow root is not recognised.
//
// The placeholder below is replaced by BrowserPageWordFilter.swift with a JSON
// array of [real, shownAs] pairs, longest real word first.
(function () {
  'use strict';

  if (window.__adkPageWordFilter) { return; }
  window.__adkPageWordFilter = true;

  var PAIRS = __ADK_PAGE_WORD_PAIRS__;
  if (!PAIRS.length) { return; }

  var replacements = new Map();
  var patterns = [];
  PAIRS.forEach(function (pair) {
    var key = pair[0].toLowerCase();
    if (replacements.has(key)) { return; }
    replacements.set(key, pair[1]);
    patterns.push(pair[0].replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  });
  // Longest first, so at each position the longest real word wins, as in
  // TextSubstitutionFilter; one pass, so a stand-in is never rewritten again.
  var matcher = new RegExp(patterns.join('|'), 'gi');

  // The stand-in in the case of the word it replaces, as
  // TextSubstitutionFilter.casing(_:like:) writes it: all capitals, all lower
  // case, or a capital then lower case; otherwise as the pair gives it.
  function cased(shown, match) {
    var upper = match.toUpperCase(), lower = match.toLowerCase();
    if (match === upper && match !== lower) { return shown.toUpperCase(); }
    if (match === lower && match !== upper) { return shown.toLowerCase(); }
    var first = match.charAt(0), rest = match.slice(1);
    if (first === first.toUpperCase() && first !== first.toLowerCase() && rest === rest.toLowerCase()) {
      return shown.charAt(0).toUpperCase() + shown.slice(1).toLowerCase();
    }
    return shown;
  }

  function substitute(text) {
    if (!text) { return text; }
    matcher.lastIndex = 0;
    return text.replace(matcher, function (match) {
      var shown = replacements.get(match.toLowerCase());
      return shown === undefined ? match : cased(shown, match);
    });
  }

  var SKIPPED = { SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, TEXTAREA: 1, TEMPLATE: 1 };
  var ATTRIBUTES = ['title', 'alt', 'placeholder', 'aria-label'];
  // What this script last wrote into each text node, so its own write is not
  // taken for a change and rewritten again (a stand-in that is itself another
  // pair's real word would otherwise be replaced twice).
  var written = new WeakMap();
  // The same for attributes: element -> { name: value written }.
  var writtenAttributes = new WeakMap();
  var observed = new WeakSet();

  function skips(node) {
    var element = node.nodeType === 1 ? node : node.parentElement;
    for (var current = element; current; current = current.parentElement) {
      if (SKIPPED[current.tagName]) { return true; }
      if (current.isContentEditable) { return true; }
    }
    return false;
  }

  function filterText(node) {
    if (written.get(node) === node.data || skips(node)) { return; }
    var next = substitute(node.data);
    if (next !== node.data) { node.data = next; }
    written.set(node, node.data);
  }

  function filterAttributes(element) {
    var mine = writtenAttributes.get(element);
    for (var i = 0; i < ATTRIBUTES.length; i++) {
      var name = ATTRIBUTES[i];
      var value = element.getAttribute(name);
      if (value === null || (mine && mine[name] === value)) { continue; }
      var next = substitute(value);
      if (!mine) { mine = {}; writtenAttributes.set(element, mine); }
      mine[name] = next;
      if (next !== value) { element.setAttribute(name, next); }
    }
  }

  function filterTree(root) {
    if (root.nodeType === 3) { filterText(root); return; }
    if (root.nodeType !== 1 && root.nodeType !== 9 && root.nodeType !== 11) { return; }
    if (root.nodeType === 1) {
      if (SKIPPED[root.tagName]) { return; }
      filterAttributes(root);
      if (root.shadowRoot) { observe(root.shadowRoot); filterTree(root.shadowRoot); }
    }
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);
    for (var node = walker.nextNode(); node; node = walker.nextNode()) {
      if (node.nodeType === 3) { filterText(node); continue; }
      filterAttributes(node);
      if (node.shadowRoot) { observe(node.shadowRoot); filterTree(node.shadowRoot); }
    }
  }

  var observer = new MutationObserver(function (records) {
    for (var i = 0; i < records.length; i++) {
      var record = records[i];
      if (record.type === 'characterData') {
        filterText(record.target);
      } else if (record.type === 'attributes') {
        if (!skips(record.target)) { filterAttributes(record.target); }
      } else {
        for (var j = 0; j < record.addedNodes.length; j++) {
          var added = record.addedNodes[j];
          if (!skips(added)) { filterTree(added); }
        }
      }
    }
  });

  function observe(root) {
    if (observed.has(root)) { return; }
    observed.add(root);
    observer.observe(root, {
      childList: true, subtree: true, characterData: true,
      attributes: true, attributeFilter: ATTRIBUTES
    });
  }

  observe(document);
  filterTree(document);
})();
