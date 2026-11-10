
- **TypeScript/React/Web**: Files `packages/web/packages/landing/src/blocks/Roadmap.tsx`. Renders a `div` with class `lp-roadmap` and conditionally renders an optional `span` with class `lp-eyebrow`. When eyebrow prop is undefined, the span element is omitted entirely rather than rendered empty to avoid unintended layout gaps.
- **SwiftUI**: Use a `VStack` with optional top section containing a `Text` view styled as an eyebrow label. Use `@ViewBuilder` or conditional rendering (`if eyebrow != nil { ... }`) to omit the label section entirely when no eyebrow is provided, preserving layout spacing.
- **Compose**: Use a `Column` with optional top `Text` composable for the eyebrow, conditionally rendered. Omit the eyebrow composable entirely when not provided to prevent layout shifts from empty slots.
- **AppKit / UIKit**: Use `NSStackView` (AppKit, vertical axis) or `UIStackView` (UIKit, vertical axis). Add an optional `NSTextField` (AppKit) or `UILabel` (UIKit) for the eyebrow label as the first arranged view, removing it from the stack when no eyebrow is provided rather than hiding it invisibly.
- **WinUI 3**: Use a `StackPanel` with vertical orientation. Add an optional `TextBlock` at the top for the eyebrow label, removing it entirely from the panel's Children when no eyebrow is provided to avoid vertical spacing artifacts from an empty element.

