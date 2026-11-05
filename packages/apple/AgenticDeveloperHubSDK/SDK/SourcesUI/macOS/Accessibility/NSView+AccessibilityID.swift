import AppKit

// Moved down from AgenticDeveloperHubSDKMacOS. Chrome views in this framework have to
// be addressable by UI tests, and this framework cannot import the one that
// used to own the helper. Every previous call site still resolves it: the two
// AgenticDeveloperHubSDK macOS frameworks `@_exported import AgenticDeveloperHubSDKUI`.

extension NSView {
    @discardableResult
    public func accessibilityID(_ identifier: String) -> Self {
        setAccessibilityIdentifier(identifier)
        return self
    }
}

extension NSMenuItem {
    @discardableResult
    public func accessibilityID(_ identifier: String) -> Self {
        setAccessibilityIdentifier(identifier)
        return self
    }
}

extension NSWindow {
    @discardableResult
    public func accessibilityID(_ identifier: String) -> Self {
        setAccessibilityIdentifier(identifier)
        return self
    }
}

public enum AccessibilityID {
    /// Lowercase-kebab id derived from a human or camelCase title.
    /// Splits on whitespace, punctuation, *and* camelCase boundaries
    /// (`aiChat` → `ai-chat`, `Session Window` → `session-window`).
    public static func slug(_ title: String) -> String {
        var spaced = ""
        var previous: Character?
        for character in title {
            if character.isUppercase, let prev = previous, prev.isLowercase {
                spaced.append(" ")
            }
            spaced.append(character)
            previous = character
        }
        return spaced.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
