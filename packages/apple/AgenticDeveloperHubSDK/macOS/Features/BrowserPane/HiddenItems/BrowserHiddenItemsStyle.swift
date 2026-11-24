//
//  BrowserHiddenItemsStyle.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// "Hide distracting items": the style that takes the user list's enabled
/// selectors off the page (recipe `workspace/browser/hidden-items-rendering`).
/// The engine runs these scripts; this is the one place that knows what they
/// say (`dry`), following `BrowserHiddenImages`' pattern: a `WKUserScript` at
/// document start plus the same script evaluated into the page showing.
///
/// One `<style id="__adk_hidden_items">` holds one
/// `<selector> { display: none !important; }` rule per selector. Being style
/// rules, they also hide matching content the page adds later, with no
/// observer. Each rule goes in through its own `insertRule`, after a
/// `CSS.supports('selector(…)')` check, inside its own `try`, so a selector
/// the page's engine rejects is skipped alone and never disables the rest.
/// Selectors reach the script as a JSON array, never pasted into its source:
/// they are user-picked data and can hold quotes.
///
/// A page whose Content Security Policy refuses inline styles gives the
/// element no sheet; the rules then go in an adopted constructed sheet,
/// which `style-src` does not govern, and the element stays as the marker.
///
/// The script runs in the page's content world (the selectors were picked
/// from the page itself, so the page learns nothing new from them).
public enum BrowserHiddenItemsStyle {

    /// The saved list's style element.
    public static let styleElementID = "__adk_hidden_items"

    /// The picker dialog's temporary "Show page with selected element
    /// removed" rule set, kept apart from the saved list's.
    public static let previewStyleElementID = "__adk_hidden_items_preview"

    /// What follows every selector in its rule.
    static let ruleBody = " { display: none !important; }"

    /// One rule per selector, one per line. The scripts build the same text
    /// rule by rule in the page; this is that text, for reading and tests.
    public static func css(selectors: [String]) -> String {
        selectors.map { $0 + ruleBody }.joined(separator: "\n")
    }

    /// The document-start user script: the same work as `applyScript`, run
    /// as the new document begins.
    public static func installScript(selectors: [String]) -> String {
        script(elementID: styleElementID, selectors: selectors)
    }

    /// Replaces the saved list's rules on the page showing; an empty list
    /// removes the element, so the page draws as it is.
    public static func applyScript(selectors: [String]) -> String {
        script(elementID: styleElementID, selectors: selectors)
    }

    /// The preview rule set's script; an empty list removes its element.
    public static func previewScript(selectors: [String]) -> String {
        script(elementID: previewStyleElementID, selectors: selectors)
    }

    private static func json<T: Encodable>(_ value: T) -> String {
        // JSONEncoder escapes `/`, so a `</script>` in a selector stays data too.
        String(data: (try? JSONEncoder().encode(value)) ?? Data(), encoding: .utf8) ?? "null"
    }

    /// Puts exactly one element with `elementID` on the page, holding only
    /// `selectors`' rules, or none at all when `selectors` is empty. Before
    /// the document has a root element it waits for `DOMContentLoaded`.
    static func script(elementID: String, selectors: [String]) -> String {
        """
        (() => {
          const ID = \(json(elementID));
          const selectors = \(json(selectors));
          const BODY = \(json(ruleBody));
          const KEY = Symbol.for(ID);
          const fill = (sheet) => {
            for (const selector of selectors) {
              if (typeof selector !== 'string' || selector.trim() === '') continue;
              try {
                if (typeof CSS !== 'undefined' && typeof CSS.supports === 'function'
                    && !CSS.supports('selector(' + selector + ')')) continue;
                sheet.insertRule(selector + BODY, sheet.cssRules.length);
              } catch (e) {}
            }
          };
          const apply = () => {
            const doc = document;
            const adopted = doc[KEY];
            if (adopted) {
              try { doc.adoptedStyleSheets = doc.adoptedStyleSheets.filter((s) => s !== adopted); } catch (e) {}
              doc[KEY] = undefined;
            }
            const existing = doc.getElementById(ID);
            if (selectors.length === 0) { existing?.remove(); return true; }
            const root = doc.head || doc.documentElement;
            if (!root && !existing) return false;
            const style = doc.createElement('style');
            style.id = ID;
            if (existing) existing.replaceWith(style); else root.appendChild(style);
            if (style.sheet) { fill(style.sheet); return true; }
            try {
              const sheet = new CSSStyleSheet();
              fill(sheet);
              doc.adoptedStyleSheets = [...doc.adoptedStyleSheets, sheet];
              doc[KEY] = sheet;
            } catch (e) {}
            return true;
          };
          if (!apply()) document.addEventListener('DOMContentLoaded', apply, { once: true });
        })();
        """
    }
}
