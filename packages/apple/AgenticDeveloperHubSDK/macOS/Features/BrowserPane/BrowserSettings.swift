//
//  BrowserSettings.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import AgenticDeveloperHubSDKCore

// MARK: - Choice types

/// How long the browser keeps a visit before forgetting it.
public enum BrowserHistoryRetention: String, Codable, Sendable, CaseIterable {
    case oneWeek
    case oneMonth
    case threeMonths
    case oneYear
    case forever

    public var label: String {
        switch self {
        case .oneWeek: "One week"
        case .oneMonth: "One month"
        case .threeMonths: "Three months"
        case .oneYear: "One year"
        case .forever: "Forever"
        }
    }

    /// Visits before this instant are forgotten; `nil` keeps everything.
    public func cutoff(from now: Date = Date()) -> Date? {
        let day: TimeInterval = 24 * 60 * 60
        switch self {
        case .oneWeek: return now.addingTimeInterval(-7 * day)
        case .oneMonth: return now.addingTimeInterval(-30 * day)
        case .threeMonths: return now.addingTimeInterval(-90 * day)
        case .oneYear: return now.addingTimeInterval(-365 * day)
        case .forever: return nil
        }
    }
}

/// What a page may do with the camera and microphone.
public enum BrowserMediaCapturePolicy: String, Codable, Sendable, CaseIterable {
    case ask
    case allow
    case deny

    public var label: String {
        switch self {
        case .ask: "Ask each time"
        case .allow: "Always allow"
        case .deny: "Never allow"
        }
    }
}

/// Whether a page may start playing media on its own.
public enum BrowserAutoplayPolicy: String, Codable, Sendable, CaseIterable {
    case allowed
    case mutedOnly
    case never

    public var label: String {
        switch self {
        case .allowed: "Allowed"
        case .mutedOnly: "Only without sound"
        case .never: "Never"
        }
    }
}

/// Whether the page receives keyboard input.
public enum BrowserInputPolicy: String, Codable, Sendable, CaseIterable {
    case allow
    case block

    public var label: String {
        switch self {
        case .allow: "Allowed"
        case .block: "Blocked"
        }
    }
}

/// When the pane reports the pointer to the page.
public enum BrowserPointerTracking: String, Codable, Sendable, CaseIterable {
    case always
    case whenFocused
    case never

    public var label: String {
        switch self {
        case .always: "Always"
        case .whenFocused: "Only while the page has focus"
        case .never: "Never"
        }
    }
}

/// How much of the browser the agent may see and drive.
public enum BrowserAgentAccess: String, Codable, Sendable, CaseIterable {
    case hidden
    case readOnly
    case full

    public var label: String {
        switch self {
        case .hidden: "Hidden from the agent"
        case .readOnly: "Read only"
        case .full: "Full control"
        }
    }
}

/// Whether the agent keeps driving the browser while the user has paused it.
public enum BrowserAgentWhilePaused: String, Codable, Sendable, CaseIterable {
    case allowed
    case paused

    public var label: String {
        switch self {
        case .allowed: "Agent may still drive"
        case .paused: "Agent pauses too"
        }
    }
}

/// Which cookie and site-data store a browser pane shares.
public enum BrowserStorageJar: String, Codable, Sendable, CaseIterable {
    case global
    case worktree
    case pane

    /// The setting's key, spelled once for `UserSettings.browserPrivacyStorageJar`
    /// and for the project database's upgrade step, which runs off the main
    /// actor and cannot read the setting object itself.
    public static let settingName = "browser.privacy.storage_jar"

    public var label: String {
        switch self {
        case .global: "Shared by all browser panes"
        case .worktree: "Shared within this worktree"
        case .pane: "This pane only"
        }
    }
}

/// Which third-party content a page may load.
public enum BrowserThirdPartyContent: String, Codable, Sendable, CaseIterable {
    case allow
    case blockScripts
    case blockAll

    public var label: String {
        switch self {
        case .allow: "Allowed"
        case .blockScripts: "Block third-party scripts"
        case .blockAll: "Block all third-party content"
        }
    }
}

// MARK: - Keys

/// The browser pane's settings. Every key starts with `browser.`, which is
/// what `BrowserSettings.reset(in:)` leans on, and a key name is a storage
/// format once shipped: renaming one orphans the value under it.
extension UserSettings {

    // General
    public static let browserHomePage = UserSetting<String>("browser.home_page", default: "")
    public static let browserPageZoom = UserSetting<Double>("browser.page_zoom", default: 1.0)
    public static let browserMinimumFontSize = UserSetting<Int>("browser.minimum_font_size", default: 0)
    public static let browserJavaScriptEnabled = UserSetting<Bool>("browser.javascript_enabled", default: true)
    public static let browserBlocksPopups = UserSetting<Bool>("browser.blocks_popups", default: true)
    public static let browserCustomUserAgent = UserSetting<String>("browser.custom_user_agent", default: "")

    // History
    public static let browserRecordsHistory = UserSetting<Bool>("browser.records_history", default: true)
    public static let browserHistoryRetention = UserSetting<BrowserHistoryRetention>(
        "browser.history_retention", default: .forever
    )

    // Cookies and site data
    public static let browserAcceptsCookies = UserSetting<Bool>("browser.accepts_cookies", default: true)
    public static let browserPrivateBrowsing = UserSetting<Bool>("browser.private_browsing", default: false)

    // Privacy and security
    public static let browserFraudWarning = UserSetting<Bool>("browser.fraud_warning", default: true)
    public static let browserUpgradesToHTTPS = UserSetting<Bool>("browser.upgrades_to_https", default: true)
    public static let browserLockdownMode = UserSetting<Bool>("browser.lockdown_mode", default: false)

    // Media and permissions
    public static let browserAutoplay = UserSetting<BrowserAutoplayPolicy>("browser.autoplay", default: .mutedOnly)
    public static let browserAllowsAirPlay = UserSetting<Bool>("browser.allows_airplay", default: true)
    public static let browserMediaCapture = UserSetting<BrowserMediaCapturePolicy>(
        "browser.media_capture", default: .ask
    )

    // Downloads
    public static let browserDownloadDirectory = UserSetting<String>("browser.download_directory", default: "")
    public static let browserAsksDownloadLocation = UserSetting<Bool>("browser.asks_download_location", default: false)

    // Session privacy
    public static let browserPrivacyKeyboard = UserSetting<BrowserInputPolicy>(
        "browser.privacy.keyboard", default: .allow
    )
    public static let browserPrivacyMouse = UserSetting<BrowserInputPolicy>("browser.privacy.mouse", default: .allow)
    public static let browserPrivacyPointerTracking = UserSetting<BrowserPointerTracking>(
        "browser.privacy.pointer_tracking", default: .always
    )
    public static let browserPrivacyDragAndDrop = UserSetting<Bool>("browser.privacy.drag_and_drop", default: true)
    public static let browserPrivacyHideActivation = UserSetting<Bool>(
        "browser.privacy.hide_activation", default: false
    )
    public static let browserPrivacyAgentAccess = UserSetting<BrowserAgentAccess>(
        "browser.privacy.agent_access", default: .full
    )
    public static let browserPrivacyAgentWhilePaused = UserSetting<BrowserAgentWhilePaused>(
        "browser.privacy.agent_while_paused", default: .allowed
    )
    public static let browserPrivacyStorageJar = UserSetting<BrowserStorageJar>(
        BrowserStorageJar.settingName, default: .pane
    )
    public static let browserPrivacyThirdPartyContent = UserSetting<BrowserThirdPartyContent>(
        "browser.privacy.third_party_content", default: .allow
    )
    public static let browserPrivacyConsoleCapture = UserSetting<Bool>("browser.privacy.console_capture", default: true)

    // Developer
    public static let browserWebInspectorEnabled = UserSetting<Bool>("browser.web_inspector_enabled", default: false)

    // Chrome only. The Safari-only keys above keep the names they shipped
    // with; these are new, so they say which browser they belong to.
    public static let browserChromeDevToolsEnabled = UserSetting<Bool>(
        "browser.chrome.devtools_enabled", default: false
    )
    /// 0 is off. Chromium reads it once, when it starts.
    public static let browserChromeRemoteDebuggingPort = UserSetting<Int>(
        "browser.chrome.remote_debugging_port", default: 0
    )
    /// Chromium reads it once, when it starts.
    public static let browserChromeHardwareAcceleration = UserSetting<Bool>(
        "browser.chrome.hardware_acceleration", default: true
    )

    // Automation
    public static let browserAutomationEnabled = UserSetting<Bool>("browser.automation.enabled", default: true)
    public static let browserAutomationEvaluate = UserSetting<Bool>("browser.automation.evaluate", default: false)
}

// MARK: - Derived values and reset

/// Readers of the browser settings that need more than the raw value.
@MainActor
public enum BrowserSettings {

    /// Every browser key, so a reset forgets all of them and nothing else.
    /// Listed rather than discovered by prefix: `keys(withPrefix:)` sees only
    /// what has been written, and a reset must also answer "what *are* the
    /// browser settings" to the panel that shows them.
    ///
    /// The automation switches are not here on purpose. "Reset browser
    /// settings" means the browsing preferences; it must not turn model
    /// access back on for a user who turned it off, nor turn `browser_evaluate`
    /// off for one who turned it on. Those two are reset from their own panel.
    /// The keys that are here for the same reason are in `keptByResetNames`.
    static let allKeys: [any BrowserSettingKey] = [
        UserSettings.browserHomePage, UserSettings.browserPageZoom, UserSettings.browserMinimumFontSize,
        UserSettings.browserJavaScriptEnabled, UserSettings.browserBlocksPopups,
        UserSettings.browserCustomUserAgent, UserSettings.browserRecordsHistory,
        UserSettings.browserHistoryRetention, UserSettings.browserAcceptsCookies,
        UserSettings.browserPrivateBrowsing, UserSettings.browserFraudWarning,
        UserSettings.browserUpgradesToHTTPS, UserSettings.browserLockdownMode,
        UserSettings.browserAutoplay, UserSettings.browserAllowsAirPlay, UserSettings.browserMediaCapture,
        UserSettings.browserDownloadDirectory, UserSettings.browserAsksDownloadLocation,
        UserSettings.browserWebInspectorEnabled, UserSettings.browserChromeDevToolsEnabled,
        UserSettings.browserChromeRemoteDebuggingPort, UserSettings.browserChromeHardwareAcceleration,
        UserSettings.browserPrivacyKeyboard, UserSettings.browserPrivacyMouse,
        UserSettings.browserPrivacyPointerTracking, UserSettings.browserPrivacyDragAndDrop,
        UserSettings.browserPrivacyHideActivation, UserSettings.browserPrivacyAgentAccess,
        UserSettings.browserPrivacyAgentWhilePaused, UserSettings.browserPrivacyStorageJar,
        UserSettings.browserPrivacyThirdPartyContent, UserSettings.browserPrivacyConsoleCapture
    ]

    /// The remote-debugging ports the Chrome topic accepts; 0 is off.
    public static let chromeRemoteDebuggingPortRange: ClosedRange<Int> = 0...65535

    /// The names of every browser key, for a test to hold the list to.
    public static var allKeyNames: [String] { allKeys.map(\.name) }

    /// Read only when the web view is built, so changing one rebuilds it.
    public static let constructionTimeKeyNames: Set<String> = [
        UserSettings.browserPrivacyStorageJar.name,
        UserSettings.browserUpgradesToHTTPS.name,
        UserSettings.browserAllowsAirPlay.name,
        UserSettings.browserAutoplay.name,
        UserSettings.browserPrivacyConsoleCapture.name,
        UserSettings.browserPrivateBrowsing.name
    ]

    /// Cannot be overridden per pane, so it is only ever read from the global
    /// settings. Chrome's remote debugging port and hardware acceleration are
    /// fixed when Chromium starts, for every Chrome pane at once.
    public static let globalOnlyKeyNames: Set<String> = [
        UserSettings.browserPrivateBrowsing.name,
        UserSettings.browserChromeRemoteDebuggingPort.name,
        UserSettings.browserChromeHardwareAcceleration.name
    ]

    /// What `store` holds for every construction-time key, each described as
    /// text so keys of different types compare in one dictionary. A pane
    /// keeps the snapshot it was built with; a later snapshot that differs is
    /// a web view that no longer matches its settings.
    static func constructionSnapshot(in store: SettingsStore) -> [String: String] {
        var snapshot: [String: String] = [:]
        for key in allKeys where constructionTimeKeyNames.contains(key.name) {
            snapshot[key.name] = key.describe(in: store)
        }
        return snapshot
    }

    /// Browser keys a reset leaves as they are, for the automation switches'
    /// reason: agent access and agent-while-paused would hand a pane the
    /// user hid or made read only back to the model, and the storage jar
    /// would move panes off their worktree jar, which the reconciler then
    /// deletes — site data the reset promises not to touch.
    public static let keptByResetNames: Set<String> = [
        UserSettings.browserPrivacyAgentAccess.name,
        UserSettings.browserPrivacyAgentWhilePaused.name,
        UserSettings.browserPrivacyStorageJar.name
    ]

    /// Puts every browser setting but `keptByResetNames` back to its default
    /// by removing the stored value, so what the default *is* stays declared
    /// in one place.
    public static func reset(in store: SettingsStore) {
        for key in allKeys where !keptByResetNames.contains(key.name) { key.remove(from: store) }
    }

    /// The home page the setting names, or `nil` when it is blank or not an
    /// address. Resolved the way the address bar resolves what is typed, so
    /// `example.com` works in both places.
    public static func homePage(in store: SettingsStore) -> URL? {
        let entry = store.get(UserSettings.browserHomePage)
        guard !entry.isEmpty else { return nil }
        return WebBrowserPaneViewController.resolveAddress(entry)
    }

    /// Where downloads land when the setting is blank.
    public static var defaultDownloadDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }

    /// The download folder: the setting when it names one, else `~/Downloads`.
    public static func downloadDirectory(in store: SettingsStore) -> URL {
        let path = store.get(UserSettings.browserDownloadDirectory)
        guard !path.isEmpty else { return defaultDownloadDirectory }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    }

    /// The page-zoom range the panel offers and the pane clamps to.
    public static let pageZoomRange: ClosedRange<Double> = 0.5...3.0

    /// The minimum-font-size range, in points; 0 means WebKit's own.
    public static let minimumFontSizeRange: ClosedRange<Int> = 0...24
}

/// A key that can remove itself from a store without the caller knowing its
/// value type — what lets `reset(in:)` hold keys of mixed types in one list.
@MainActor
protocol BrowserSettingKey {
    var name: String { get }
    func remove(from store: SettingsStore)
    /// The value `store` resolves for this key, as text.
    func describe(in store: SettingsStore) -> String
}

extension UserSetting: BrowserSettingKey {
    func remove(from store: SettingsStore) { store.remove(self) }
    func describe(in store: SettingsStore) -> String { String(describing: store.get(self)) }
}
