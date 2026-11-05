#if os(macOS)
import AppKit

public typealias PlatformViewController = NSViewController
public typealias PlatformTextView = NSTextView
#else
import UIKit

public typealias PlatformViewController = UIViewController
public typealias PlatformTextView = UITextView
#endif

// `PlatformView` itself is already declared in
// `SourcesUI/Shared/Theme/ThemeScopeResolution.swift` — same meaning, same
// module, so it is reused here rather than redeclared.
