
- **React/Web**: Implemented in `packages/web/packages/landing/src/deck/Glow.tsx` as a functional component. Exports a `Glow` function accepting `{ className?: string }`. Combines 'lp-glow' base class with the optional className prop using `[...].filter(Boolean).join(' ')`. The rendered `<div>` is always `aria-hidden`. Visual styling is delegated entirely to CSS classes in the application's stylesheet (`css/base.css`'s `.lp-glow` rule), with the hero variant's positioning offset derived from the hero's padding custom properties.

- **SwiftUI**: Implement using a transparent `View` with a `RadialGradient` or layered `Canvas` to create the glow effect. Apply `.accessibilityHidden(true)` to exclude from VoiceOver and `.allowsHitTesting(false)` to keep it non-interactive. Use environment or view properties to apply styling derived from design tokens that match the web CSS definitions.

- **Compose**: Use a `Box` or `Canvas` composable with `Brush.radialGradient` or a `blur` modifier to produce the glow. Apply `Modifier.clearAndSetSemantics {}` to hide the purely decorative node from accessibility services. Layer multiple elements with alpha blending if needed to achieve the visual effect.

- **AppKit / UIKit**: On macOS, create an `NSView` subclass with `CAGradientLayer` (radial) or custom drawing for the glow, call `setAccessibilityElement(false)`, and override `hitTest(_:)` to return `nil` so the view never intercepts clicks. On iOS, use a `UIView` with `CAGradientLayer` or similar, set `isAccessibilityElement = false`, `accessibilityElementsHidden = true`, and `isUserInteractionEnabled = false`.

- **WinUI 3**: Render a `Border` or `Grid` with a `RadialGradientBrush` to create the glow effect. Set `IsHitTestVisible="False"` to prevent interaction. Apply `AutomationProperties.AccessibilityView="Raw"` to remove it from the automation tree (`IsOffscreenBehavior` does not remove an element from the tree, and `UIElement` has no `Effect`/`BlurEffect` property — those are WPF-only). Achieve the blur, if wanted, with a Composition `GaussianBlurEffect` via Win2D, or approximate it with a feathered `RadialGradientBrush`.

