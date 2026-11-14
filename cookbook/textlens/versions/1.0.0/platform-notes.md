
- **React/Web**: implemented in `packages/web/packages/textlens/src/color.ts`
  (`parseColor`, `resolveColor`), `lens.ts` (`createLens`, `Lens`,
  `LensOptions`), and `useTextLens.ts` (`useTextLens`,
  `UseTextLensOptions`), re-exported from `index.ts`. `useTextLens.ts` is
  marked `'use client'` for Next.js/RSC boundaries. There is no CSS to
  import — the effect writes inline `transform`/`color`/`filter` styles
  only, and any colour ramp is expected to live in the stylesheet as CSS
  custom properties the lens reads via `getComputedStyle`.
- **SwiftUI**: there is no per-glyph inline-style equivalent; build the
  sweep as a `TimelineView`- or `CADisplayLink`-driven per-character `Text`
  layout (an `HStack` of single-character `Text` views, each carrying its
  own `.scaleEffect`/`.blur`/`.foregroundStyle` derived from its distance to
  a `@State` sweep-centre value), with the colour ramp resolved once at
  start from `Color(nsColor/uiColor:)` or a design-token asset rather than a
  raw CSS custom property.
- **Compose**: lay the text out as a `Row` of single-character
  `Text`/`BasicText` composables inside a `Layout` that reports each
  child's centre, drive the sweep centre from a
  `withInfiniteAnimationFrameMillis`/`Animatable` value, and apply
  `Modifier.graphicsLayer { scaleX = ...; scaleY = ... }` plus a
  `renderEffect`/`BlurEffect` for the blur and `Modifier.drawWithContent` or
  a `Color` lerp for the tint — Compose's reduced-motion signal is
  `LocalAccessibilityManager`/the platform's "remove animations"
  accessibility setting rather than a CSS media query.
- **AppKit / UIKit**: split the label into one `NSTextField`/`UILabel` (or
  `CATextLayer`) per character, frozen at its measured width in an
  `NSStackView`/`UIStackView` (or manual frame layout) the same way the web
  split freezes span widths, and drive `transform`/`shadowRadius`/
  `textColor` per frame from a `CADisplayLink`; gate the sweep on
  `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (AppKit) or
  `UIAccessibility.isReduceMotionEnabled` (UIKit) in place of the web's
  `prefers-reduced-motion` query.
- **WinUI 3**: split the text into one `TextBlock` per character inside a
  `StackPanel Orientation="Horizontal"` (or a custom `Panel` that reports
  each child's centre), and drive the sweep from a per-frame
  `CompositionTarget.Rendering` handler (the closest analogue to
  `requestAnimationFrame`) writing each `TextBlock`'s `ScaleTransform`,
  a `Composition` `GaussianBlurEffect` via Win2D, and `Foreground` from a
  linear channel interpolation matching **colour-interpolation**. Gate the
  sweep on `Windows.UI.ViewManagement.UISettings.AnimationsEnabled` (the
  Windows equivalent of `prefers-reduced-motion`) in place of the web's
  media query, and resolve the colour ramp from an
  `Application.Current.Resources` brush lookup rather than a CSS custom
  property, since WinUI has no per-element computed-style read equivalent
  to `getComputedStyle`.

