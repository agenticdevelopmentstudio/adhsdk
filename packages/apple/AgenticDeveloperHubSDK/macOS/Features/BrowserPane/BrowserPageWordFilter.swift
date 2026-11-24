//
//  BrowserPageWordFilter.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import os
import AgenticDeveloperHubSDKCore

/// Agent Privacy on the page a pane draws: the script that rewrites each real
/// privacy word in the page's text as the word it is shown as, so the pane
/// shows the page the way a private terminal shows its output, and a model
/// reading the page reads the same stand-ins.
///
/// Both engines inject the same script (`BrowserPageWordFilter.js`), at
/// document start, in every frame, in the isolated world `worldName`, never
/// the page world, where a page could read the user's whole word list. An
/// engine applies a change by reloading: text the script already rewrote
/// cannot be put back, and a reload is the one path that is right for
/// turning it on, off and changing the words alike (`simplicity`).
public enum BrowserPageWordFilter {

    /// The comment the script starts with.
    public static let marker = "/* adk-page-word-filter */"

    /// The isolated world the script runs in, in both engines.
    public static let worldName = "adk-page-word-filter"

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    private final class BundleToken {}

    /// The script as bundled, placeholder and all; `nil` when the resource is
    /// missing, which leaves the page as it is.
    private static let template: String? = {
        guard let url = Bundle(for: BundleToken.self)
            .url(forResource: "BrowserPageWordFilter", withExtension: "js"),
            let text = try? String(contentsOf: url, encoding: .utf8) else {
            logger.error("BrowserPageWordFilter.js is missing from the framework; pages are drawn unfiltered")
            return nil
        }
        return text
    }()

    /// The script for `filter`, with its pairs written in as a JSON array of
    /// `[real, shownAs]`, longest real word first; `nil` when the filter has
    /// no pairs or the resource is missing.
    public static func script(for filter: TextSubstitutionFilter) -> String? {
        guard !filter.pairs.isEmpty, let template else { return nil }
        let pairs = filter.pairs
            .sorted { $0.real.count > $1.real.count }
            .map { [$0.real, $0.alias] }
        guard let data = try? JSONSerialization.data(withJSONObject: pairs),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return template.replacingOccurrences(of: "__ADK_PAGE_WORD_PAIRS__", with: json)
    }
}
