#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The platform's native color/font types, named so shared code never writes
/// `#if os(macOS)` to pick between `NSColor`/`UIColor` or `NSFont`/`UIFont`.
/// Each platform's Theme folder supplies the accessors that produce these —
/// `SemanticPalette.platformColor(_:)`/`platformFont(_:)` — forwarding to its
/// existing bridge on macOS (`nsColor(_:)`/`font(_:)`) and a new one on iOS.
#if os(macOS)
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
#else
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
#endif
