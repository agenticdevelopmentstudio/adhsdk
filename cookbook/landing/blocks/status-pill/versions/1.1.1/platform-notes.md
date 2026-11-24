
- **React/Web**: Component is defined in `packages/web/packages/landing/src/blocks/StatusPill.tsx`. Renders a `<p>` element with conditional CSS class application via `['lp-status', free === true ? 'lp-status--free' : ''].filter(Boolean).join(' ')`. Props are `children: ReactNode` and optional `free?: boolean`. Base and accent styling live in the `lp-status` / `lp-status--free` rules in `blocks.css` (see **Appearance**).

- **SwiftUI**: Implement as `Text` inside a pill shape. Do not clip with `.clipShape(Capsule())`, since that also clips the border stroke; instead apply `.background(Capsule().fill(backgroundColor))` and `.overlay(Capsule().stroke(borderColor, lineWidth: 1))`, switching `backgroundColor`/`borderColor` on an `isFree: Bool` parameter. Match font, letter-spacing, and uppercase casing to the source tokens (see **Localization** for the uppercase caveat).

- **Compose**: Implement using a `Text` composable inside a `Box` or `Surface`. Apply the pill shape via `shape = RoundedCornerShape(percent = 50)`, and switch the `background()`/`border()` colors on a Boolean `free` parameter, matching the source's default vs. accent tokens.

- **AppKit / UIKit**: Implement as a `UILabel` (UIKit) or `NSTextField` (AppKit) inside a small container view that draws the pill's background and border. Apply the pill shape via `layer.cornerRadius = bounds.height / 2`, and switch the border/background colors on an `isFree` property, matching the source's default vs. accent tokens.

- **WinUI 3**: Implement as a `TextBlock` inside a `Border`. Set `CornerRadius` to half the rendered height (not a fixed value) so the shape stays a pill at any size, and use `Border.Padding` — not `Margin` — to reproduce the `0.32rem × 0.6rem` padding. Switch `Background` and `BorderBrush` on a `Free` dependency property. Leave `HorizontalAlignment`/`VerticalAlignment` to the parent layout rather than fixing them on the pill itself.

