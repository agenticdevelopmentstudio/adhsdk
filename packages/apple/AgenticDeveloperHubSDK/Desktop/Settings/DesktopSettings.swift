import Combine
import CoreGraphics
import Foundation
import AgenticDeveloperHubSDKCore

/// Where the Desktop shows App menus.
public enum DesktopMenuStyle: String, Codable, Sendable, CaseIterable {
    /// One menu bar across the top of the Desktop, showing the front window's menus.
    case macOS
    /// A menu bar inside each App window, under its title bar.
    case windows
}

/// The Desktop's own persisted settings: background, icon arrangement, and
/// remembered icon positions and window frames.
@MainActor
public final class DesktopSettings {
    public static let shared = DesktopSettings()

    enum Key {
        static let backgroundColor = "desktop.backgroundColor"
        static let backgroundImagePath = "desktop.backgroundImagePath"
        static let iconArrangement = "desktop.iconArrangement"
        static let keepArranged = "desktop.keepArranged"
        static let iconPositions = "desktop.iconPositions"
        static let windowFrames = "desktop.windowFrames"
        static let menuStyle = "desktop.menuStyle"
        static let all: Set<String> = [
            backgroundColor, backgroundImagePath, iconArrangement, keepArranged, iconPositions, windowFrames,
            menuStyle
        ]
    }

    let store: UserSettings

    public init(store: UserSettings = .shared) {
        self.store = store
    }

    /// The settings store for one App, in the same underlying store as the Desktop's own settings.
    public func appSettings(for app: DesktopApp) -> DesktopAppSettings {
        DesktopAppSettings(
            appIdentifier: app.descriptor.identifier,
            schema: app.descriptor.settingsSchema,
            store: store
        )
    }

    /// Emits whenever any Desktop setting changes.
    public var changes: AnyPublisher<Void, Never> {
        store.changes
            .filter { Key.all.contains($0) }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public var backgroundColorHex: String {
        get { read(Key.backgroundColor, default: "#3A6EA5") }
        set { write(newValue, Key.backgroundColor, default: "#3A6EA5") }
    }

    /// Nil means no photo: the Desktop shows its background color.
    public var backgroundImagePath: String? {
        get { read(Key.backgroundImagePath, default: String?.none) }
        set {
            if let newValue {
                write(newValue, Key.backgroundImagePath, default: String?.none)
            } else {
                // Remove the key rather than storing an encoded null.
                store.remove(DesktopSettingKey(name: Key.backgroundImagePath, defaultValue: String?.none))
            }
        }
    }

    public var iconArrangement: DesktopIconArrangement {
        get { read(Key.iconArrangement, default: DesktopIconArrangement.largeIcons) }
        set { write(newValue, Key.iconArrangement, default: .largeIcons) }
    }

    /// Turning this off starts free placement from the current arrangement: positions saved by an
    /// earlier free spell are dropped, so every icon stays where the arranged grid put it until it
    /// is dragged. That holds whether or not a Desktop is on screen.
    public var keepArranged: Bool {
        get { read(Key.keepArranged, default: true) }
        set {
            if keepArranged, !newValue, !iconPositions.isEmpty { iconPositions = [:] }
            write(newValue, Key.keepArranged, default: true)
        }
    }

    /// Free-placed icon positions, by App identifier.
    public var iconPositions: [String: CGPoint] {
        get { read(Key.iconPositions, default: [:]) }
        set { write(newValue, Key.iconPositions, default: [:]) }
    }

    /// Last window frames, by App identifier.
    public var windowFrames: [String: CGRect] {
        get { read(Key.windowFrames, default: [:]) }
        set { write(newValue, Key.windowFrames, default: [:]) }
    }

    /// Where App menus appear: one bar across the Desktop's top, or a bar in each window.
    public var menuStyle: DesktopMenuStyle {
        get { read(Key.menuStyle, default: DesktopMenuStyle.macOS) }
        set { write(newValue, Key.menuStyle, default: .macOS) }
    }

    private func read<Value: Codable & Sendable>(_ name: String, default fallback: Value) -> Value {
        store.get(DesktopSettingKey(name: name, defaultValue: fallback))
    }

    private func write<Value: Codable & Sendable>(_ value: Value, _ name: String, default fallback: Value) {
        store.set(value, for: DesktopSettingKey(name: name, defaultValue: fallback))
    }
}
