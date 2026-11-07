//
//  BrowserEngineKind.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Which engine a Web Browser pane draws with. The panes are otherwise the
/// same pane: one base class, one set of model tools, one settings panel.
///
/// The raw values are what the model tools take and report (`browser_open`'s
/// `engine`, `browser_list`'s `engine` column), so they are a wire format.
public enum BrowserEngineKind: String, CaseIterable, Sendable {
    /// WebKit, through `WKWebView`.
    case safari
    /// Chromium, through the Chromium Embedded Framework.
    case chrome

    /// What a pane on this engine calls itself while it shows nothing.
    public var displayName: String {
        switch self {
        case .safari: "Safari"
        case .chrome: "Chrome"
        }
    }
}
