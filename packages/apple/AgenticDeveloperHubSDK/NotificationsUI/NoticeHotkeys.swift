import Carbon.HIToolbox
import Foundation
import AgenticDeveloperHubSDKNotifications

/// Registers system-wide hotkeys. A seam, so tests never grab real keys.
@MainActor
protocol HotkeyRegistrar: AnyObject {
    /// Registers one hotkey; `false` when the system refused it (another app
    /// already holds the combination).
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) -> Bool
    func unregisterAll()
}

/// Keyboard control of the newest notice on screen, from any app. Notice
/// panels never take key focus, so these global hotkeys are how a keyboard
/// user acts on them:
///
/// - ⌃⌥⌘Return: act on it (its primary action)
/// - ⌃⌥⌘Delete: archive it
/// - ⌃⌥⌘S: snooze it 15 minutes
/// - ⌃⌥⌘H: open the history
@MainActor
public final class NoticeHotkeys {

    public enum Command: Sendable, Equatable {
        case act, archive, snooze, history
    }

    struct Binding: Equatable {
        let keyCode: UInt32
        let modifiers: UInt32
        let command: Command
    }

    static let bindings: [Binding] = {
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        return [
            Binding(keyCode: UInt32(kVK_Return), modifiers: modifiers, command: .act),
            Binding(keyCode: UInt32(kVK_Delete), modifiers: modifiers, command: .archive),
            Binding(keyCode: UInt32(kVK_ANSI_S), modifiers: modifiers, command: .snooze),
            Binding(keyCode: UInt32(kVK_ANSI_H), modifiers: modifiers, command: .history)
        ]
    }()

    private weak var center: NoticePresentationCenter?
    private let registrar: HotkeyRegistrar
    public private(set) var isEnabled = false

    /// Nothing is registered until `setEnabled(true)`.
    public convenience init(center: NoticePresentationCenter) {
        self.init(center: center, registrar: CarbonHotkeyRegistrar())
    }

    init(center: NoticePresentationCenter, registrar: HotkeyRegistrar) {
        self.center = center
        self.registrar = registrar
    }

    isolated deinit {
        if isEnabled {
            registrar.unregisterAll()
        }
    }

    /// Turns the hotkeys on or off (the settings switch). Idempotent.
    public func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        if enabled {
            for binding in Self.bindings {
                let command = binding.command
                _ = registrar.register(keyCode: binding.keyCode, modifiers: binding.modifiers) { [weak self] in
                    self?.perform(command)
                }
            }
        } else {
            registrar.unregisterAll()
        }
    }

    /// Runs a command on the newest notice still on screen. With none shown,
    /// only `history` does anything.
    public func perform(_ command: Command) {
        guard let center else { return }
        if command == .history {
            center.showHistory()
            return
        }
        guard let id = center.newestShownID else { return }
        switch command {
        case .act: center.act(id: id)
        case .archive: center.archive(id: id)
        case .snooze: center.snooze(id: id, option: .fifteenMinutes)
        case .history: break
        }
    }
}

/// Carbon `RegisterEventHotKey`, the one public API for system-wide hotkeys
/// that needs no Accessibility permission. One application event handler
/// serves every registrar; it maps the pressed hotkey's id back to its
/// closure through a main-actor table.
@MainActor
final class CarbonHotkeyRegistrar: HotkeyRegistrar {

    nonisolated private static let signature: OSType = 0x524E_4F54 // "RNOT"
    private static var handlers: [UInt32: @MainActor () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static var eventHandler: EventHandlerRef?

    private var refs: [UInt32: EventHotKeyRef] = [:]

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) -> Bool {
        Self.installEventHandlerIfNeeded()
        let id = Self.nextID
        Self.nextID += 1
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode, modifiers, EventHotKeyID(signature: Self.signature, id: id),
            GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        refs[id] = ref
        Self.handlers[id] = handler
        return true
    }

    func unregisterAll() {
        for (id, ref) in refs {
            UnregisterEventHotKey(ref)
            Self.handlers[id] = nil
        }
        refs = [:]
    }

    isolated deinit {
        unregisterAll()
    }

    private static func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var installed: EventHandlerRef?
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard status == noErr, hotKeyID.signature == CarbonHotkeyRegistrar.signature else {
                return OSStatus(eventNotHandledErr)
            }
            let id = hotKeyID.id
            // Hotkey events arrive on the main thread's event loop.
            MainActor.assumeIsolated { CarbonHotkeyRegistrar.handlers[id]?() }
            return noErr
        }, 1, &spec, nil, &installed)
        eventHandler = installed
    }
}
