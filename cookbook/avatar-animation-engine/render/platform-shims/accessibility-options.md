
| Option | Behavior |
|--------|----------|
| Reduce Motion | `Platform.reduceMotion()` reads `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (AppKit) or `UIAccessibility.isReduceMotionEnabled` (UIKit) fresh on every call; `AvatarEnvironment.live()` exposes it as the `reducedMotion` closure the engine samples elsewhere. This component only surfaces the OS setting — it does not itself change any drawing decision based on it. |
| Increase Contrast | Not applicable: neither file reads or reacts to a contrast setting; ink color values arrive from the character config verbatim. |
| Differentiate Without Color | Not applicable: paint is a single ink color used as a fill or a stroke; neither file relies on hue alone to distinguish state, nor offers an alternate encoding. |

