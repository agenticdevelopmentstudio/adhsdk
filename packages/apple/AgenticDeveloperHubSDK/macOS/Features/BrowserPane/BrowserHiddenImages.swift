//
//  BrowserHiddenImages.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Agent Privacy's Hide Images: a style sheet that draws every image on the
/// page as a crossed-out eye, put in at document start and on the page
/// showing when the setting changes. The engines run these scripts; this is
/// the one place that knows what they say (`dry`).
enum BrowserHiddenImages {

    static let styleID = "__adk_hidden_images"

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

    /// Adds the style sheet, once, as soon as there is a document to add it to.
    static var hideSource: String {
        let cssLiteral = String(data: (try? JSONEncoder().encode(css)) ?? Data(), encoding: .utf8) ?? "\"\""
        return """
            (() => {
              if (document.getElementById('\(styleID)')) return;
              const style = document.createElement('style');
              style.id = '\(styleID)';
              style.textContent = \(cssLiteral);
              (document.head || document.documentElement).appendChild(style);
            })();
            """
    }

    /// Takes the style sheet back out, so the images show again.
    static var showSource: String {
        "document.getElementById('\(styleID)')?.remove();"
    }
}
