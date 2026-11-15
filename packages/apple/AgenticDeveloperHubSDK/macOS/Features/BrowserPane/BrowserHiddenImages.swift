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
enum BrowserHiddenImages {

    static let styleID = "__adk_hidden_images"

    /// The isolated world the script runs in, so its listener and its
    /// function are out of the page's reach.
    static let worldName = "adk-hidden-images"

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

    private static var css: String {
        "img, input[type=image] { content: url(\"\(placeholder)\") !important; "
            + "object-fit: none !important; object-position: center !important; "
            + "background: rgba(128,128,128,0.15) !important; } "
            + "picture source { display: none !important; } "
            + "svg image { visibility: hidden !important; }"
    }

    private static func literal(_ string: String) -> String {
        String(data: (try? JSONEncoder().encode(string)) ?? Data(), encoding: .utf8) ?? "\"\""
    }

    /// The script with `hides` written in. At document start it applies it
    /// to the new document; run on a page already showing, it applies it to
    /// every frame of it.
    static func script(hides: Bool, token: String) -> String {
        """
        (() => {
          const KEY = '__adkHiddenImages';
          const token = \(literal(token));
          if (!window[KEY]) {
            const apply = (doc, on) => {
              const existing = doc.getElementById('\(styleID)');
              if (!on) { existing?.remove(); return; }
              if (existing) return;
              const style = doc.createElement('style');
              style.id = '\(styleID)';
              style.textContent = \(literal(css));
              (doc.head || doc.documentElement)?.appendChild(style);
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
