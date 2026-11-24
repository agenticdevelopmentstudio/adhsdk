//
//  BrowserInputGate.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import Foundation

/// The four kinds of input a browser pane can withhold from its page.
public enum BrowserInputChannel: String, Sendable {
    case keyboard
    case mouse
    case pointer
    case dragAndDrop
}

/// What a pane lets through to its page: the Session Privacy input settings
/// plus pause state, as one immutable value (`immutability-by-default`).
///
/// The pane builds a new one whenever a setting or the pause state changes and
/// hands it to its `BrowserWebView`, which asks `allows` before each event.
public struct BrowserInputGate: Sendable, Equatable {
    public var keyboard: BrowserInputPolicy
    public var mouse: BrowserInputPolicy
    public var pointer: BrowserPointerTracking
    public var dragAndDrop: Bool
    public var isPaused: Bool
    /// Whether the agent's synthesized input is held too while paused.
    public var agentPausedToo: Bool

    /// Everything allowed: the gate a web view has before its pane sets one.
    public static let open = BrowserInputGate(
        keyboard: .allow, mouse: .allow, pointer: .always, dragAndDrop: true,
        isPaused: false, agentPausedToo: false
    )

    public init(
        keyboard: BrowserInputPolicy, mouse: BrowserInputPolicy, pointer: BrowserPointerTracking,
        dragAndDrop: Bool, isPaused: Bool, agentPausedToo: Bool
    ) {
        self.keyboard = keyboard
        self.mouse = mouse
        self.pointer = pointer
        self.dragAndDrop = dragAndDrop
        self.isPaused = isPaused
        self.agentPausedToo = agentPausedToo
    }

    @MainActor
    public init(settings: SettingsStore, isPaused: Bool) {
        self.init(
            keyboard: settings.get(UserSettings.browserPrivacyKeyboard),
            mouse: settings.get(UserSettings.browserPrivacyMouse),
            pointer: settings.get(UserSettings.browserPrivacyPointerTracking),
            dragAndDrop: settings.get(UserSettings.browserPrivacyDragAndDrop),
            isPaused: isPaused,
            agentPausedToo: settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
        )
    }

    /// Whether an event on `channel` reaches the page.
    ///
    /// - Parameters:
    ///   - synthesized: The agent's own input, delivered inside
    ///     `deliveringAutomationInput`. It passes a blocked channel, because
    ///     the settings gate the user's hands, not the agent's.
    ///   - pageHasFocus: Whether the window is key and the page holds first
    ///     responder, for `pointer == .whenFocused`.
    public func allows(_ channel: BrowserInputChannel, synthesized: Bool, pageHasFocus: Bool) -> Bool {
        if synthesized { return !(isPaused && agentPausedToo) }
        if isPaused { return false }
        switch channel {
        case .keyboard: return keyboard == .allow
        case .mouse: return mouse == .allow
        case .pointer:
            switch pointer {
            case .always: return true
            case .whenFocused: return pageHasFocus
            case .never: return false
            }
        case .dragAndDrop: return dragAndDrop
        }
    }
}
