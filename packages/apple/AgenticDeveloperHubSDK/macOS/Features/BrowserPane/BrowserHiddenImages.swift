//
//  BrowserHiddenImages.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Agent Privacy's Hide Images: a style sheet that draws every image on the
/// page as a crossed-out eye, put in at document start and on the page
/// showing when the setting changes. The engines run this script; this is
/// the one place that knows what it says (`dry`).
///
/// The script runs in every frame, in the isolated world `worldName`, and is
/// installed whether the setting is on or off, with the setting written in:
/// each frame's copy keeps a listener, so a change reaches the frames already
/// loaded, cross-site ones included, not only the main document. Run again
/// with the new setting in the main frame, it applies it there and posts it
/// to each child frame, whose copy applies it and passes it on to its own
/// children. The message carries the engine's `token` and is taken only from
/// the frame's parent.
///
/// What it covers: `img` and image buttons become the eye; every background
/// image (gradients included), list-style image and border image is removed;
/// `video`, `canvas`, `embed`, `object` and SVG images are hidden. It reaches
/// open shadow roots, the ones on the page and each one added later, and
/// puts itself back when a page removes it. Each document and shadow root
/// gets the rules twice, as a `<style>` element and as an adopted
/// constructed sheet, which a page's Content Security Policy does not govern
/// (`style-src` covers style elements, never `adoptedStyleSheets`), so a page
/// that refuses inline styles still has its images hidden. macOS has no
/// public user style sheet API for `WKWebView`, which is why it is script.
///
/// What it cannot reach: an image inside a closed shadow root, an image
/// drawn as a pseudo-element's `content` (a rule for those would remove
/// every generated box, clearfixes included), and a document a page
/// rewrites with `document.open()`, until its next navigation. An agent's
/// screenshot is the pixels on screen, so it shows whatever this misses.
public enum BrowserHiddenImages {

    public static let styleID = "__adk_hidden_images"

    /// The isolated world the script runs in, so its listener and its
    /// function are out of the page's reach.
    public static let worldName = "adk-hidden-images"

    /// An eye with a line through it, grey on a faint grey tile.
    private static let placeholder: String = {
        let svg = """
            <svg xmlns='http://www.w3.org/2000/svg' width='28' height='28' viewBox='0 0 24 24' \
            fill='none' stroke='%23888' stroke-width='1.8' stroke-linecap='round'>\
            <path d='M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z'/>\
            <circle cx='12' cy='12' r='3'/><line x1='3' y1='3' x2='21' y2='21'/></svg>
            """
        return "data:image/svg+xml;utf8," + svg.replacingOccurrences(of: "\n", with: "")
    }()

    /// An image button's renderer ignores `content`, so its image is moved
    /// out of its box (a replaced element paints clipped to it) and the eye
    /// is its background instead.
    private static var css: String {
        "img { content: url(\"\(placeholder)\") !important; "
            + "object-fit: none !important; object-position: center !important; "
            + "background: rgba(128,128,128,0.15) !important; } "
            + "input[type=image] { object-fit: none !important; "
            + "object-position: -100000px 0 !important; "
            + "background: rgba(128,128,128,0.15) url(\"\(placeholder)\") center no-repeat !important; } "
            + "*, *::before, *::after { background-image: none !important; "
            + "list-style-image: none !important; border-image-source: none !important; } "
            + "video, canvas, embed, object, svg image, svg feImage { visibility: hidden !important; }"
    }

    private static func literal(_ string: String) -> String {
        String(data: (try? JSONEncoder().encode(string)) ?? Data(), encoding: .utf8) ?? "\"\""
    }

    /// The script with `hides` written in. At document start it applies it
    /// to the new document; run on a page already showing, it applies it to
    /// every frame of it.
    public static func script(hides: Bool, token: String) -> String {
        """
        (() => {
          const KEY = '__adkHiddenImages';
          const token = \(literal(token));
          if (!window[KEY]) {
            const ID = '\(styleID)';
            const css = \(literal(css));
            const OPTIONS = { childList: true, subtree: true };
            const mine = new WeakSet();
            const sheets = new WeakMap();
            const observers = new WeakMap();
            // A constructed sheet can be adopted only in the document that
            // made it, so each document gets its own, shared by its shadow
            // roots.
            const sheetFor = (doc) => {
              if (!sheets.has(doc)) {
                try {
                  const sheet = new doc.defaultView.CSSStyleSheet();
                  sheet.replaceSync(css);
                  mine.add(sheet);
                  sheets.set(doc, sheet);
                } catch (e) { sheets.set(doc, null); }
              }
              return sheets.get(doc);
            };
            // Puts the rules in one document or shadow root, or takes them out.
            const style = (root, on) => {
              const doc = root.ownerDocument || root;
              const existing = root.getElementById(ID);
              if (!on) existing?.remove();
              else if (!existing) {
                const element = doc.createElement('style');
                element.id = ID;
                element.textContent = css;
                (root === doc ? (doc.head || doc.documentElement) : root)?.appendChild(element);
              }
              try {
                const adopted = root.adoptedStyleSheets;
                const kept = adopted.filter((sheet) => !mine.has(sheet));
                const sheet = on ? sheetFor(doc) : null;
                if (sheet && !adopted.includes(sheet)) root.adoptedStyleSheets = [...kept, sheet];
                else if (!on && kept.length !== adopted.length) root.adoptedStyleSheets = kept;
              } catch (e) {}
            };
            // Every open shadow root at or under `node`, nested ones included.
            const shadowRoots = (node, found = []) => {
              const visit = (element) => {
                if (!element.shadowRoot) return;
                found.push(element.shadowRoot);
                shadowRoots(element.shadowRoot, found);
              };
              if (node.nodeType === 1) visit(node);
              if (node.querySelectorAll) for (const element of node.querySelectorAll('*')) visit(element);
              return found;
            };
            const apply = (doc, on) => {
              observers.get(doc)?.disconnect();
              observers.delete(doc);
              const roots = [doc, ...shadowRoots(doc)];
              for (const root of roots) style(root, on);
              if (!on) return;
              // A new shadow root gets the rules, and a root whose rules a
              // page removed gets them back.
              const observer = new MutationObserver((records) => {
                const touched = new Set();
                for (const record of records) {
                  touched.add(record.target.getRootNode());
                  for (const node of record.addedNodes) {
                    for (const root of shadowRoots(node)) {
                      touched.add(root);
                      observer.observe(root, OPTIONS);
                    }
                  }
                }
                for (const root of touched) {
                  if (root === doc || root instanceof doc.defaultView.ShadowRoot) style(root, true);
                }
              });
              for (const root of roots) observer.observe(root, OPTIONS);
              observers.set(doc, observer);
            };
            // A child frame with its own copy is called, a same-origin one
            // without (an about:blank frame a script wrote into) is applied
            // to directly, and a cross-origin one is posted to.
            const reach = (win, on) => {
              for (let i = 0; i < win.frames.length; i++) {
                const child = win.frames[i];
                try {
                  if (typeof child[KEY] === 'function') { child[KEY](on); continue; }
                  if (child.document) { apply(child.document, on); reach(child, on); continue; }
                } catch (e) {}
                try { child.postMessage({ [KEY]: token, hide: on }, '*'); } catch (e) {}
              }
            };
            const broadcast = (on) => { apply(document, on); reach(window, on); };
            window.addEventListener('message', (event) => {
              const data = event.data;
              if (window.parent === window || event.source !== window.parent) return;
              if (!data || typeof data !== 'object' || data[KEY] !== token) return;
              event.stopImmediatePropagation();
              broadcast(data.hide === true);
            }, true);
            window[KEY] = broadcast;
          }
          window[KEY](\(hides ? "true" : "false"));
        })();
        """
    }
}
