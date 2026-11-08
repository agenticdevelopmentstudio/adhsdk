//
//  BrowserEngineKind.swift
//  AgenticDeveloperHubSDK
//

import AppKit

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

extension BrowserEngineKind {

    /// The bundle of the browser this engine is, whose icon a pane on it shows.
    public var browserBundleIdentifier: String {
        switch self {
        case .safari: "com.apple.Safari"
        case .chrome: "com.google.Chrome"
        }
    }

    /// The SF Symbol shown when the browser itself is not installed.
    public var fallbackSymbolName: String {
        switch self {
        case .safari: "safari"
        case .chrome: "globe"
        }
    }

    /// The browser's own app icon — Safari's compass, Chrome's wheel — or the
    /// fallback symbol on a Mac without that browser. Looked up once per kind;
    /// an install made while the app runs shows after a relaunch.
    @MainActor
    public var icon: NSImage {
        if let cached = Self.icons[self] { return cached }
        let image: NSImage
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browserBundleIdentifier) {
            image = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            image = NSImage(systemSymbolName: fallbackSymbolName, accessibilityDescription: displayName)
                ?? NSImage()
        }
        image.accessibilityDescription = displayName
        Self.icons[self] = image
        return image
    }

    @MainActor private static var icons: [BrowserEngineKind: NSImage] = [:]
}
