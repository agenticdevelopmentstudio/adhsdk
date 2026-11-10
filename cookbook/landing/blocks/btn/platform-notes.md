
- **React/Web** (`packages/web/packages/landing/src/blocks/Btn.tsx`): Functional component that computes `className` as `['lp-btn', \`lp-btn--${variant}\`].join(' ')`. The rendered `className` attribute is always exactly `lp-btn lp-btn--{variant}` (e.g. `lp-btn lp-btn--primary`, `lp-btn lp-btn--ghost`), built this one way — the component does not accept a `className` prop of its own. Styling is external to the component.

- **SwiftUI**: Use `Link(destination:)` with the link text as its label content. Apply `.buttonStyle(.borderedProminent)` and `.tint(.accentColor)` for the primary (filled, accent) variant, and `.buttonStyle(.bordered)` for the ghost (outlined) variant.

- **Compose**: Use `Button` for the primary (filled) variant and `OutlinedButton` for the ghost (outlined) variant, calling `LocalUriHandler.current.openUri(href)` from `onClick` to navigate. Place the link text in the composable's `content` lambda.

- **AppKit / UIKit**: AppKit — use `NSButton` with `bezelStyle` and `bezelColor` set to the accent color for primary, and a borderless/outline bezel for ghost. UIKit — use `UIButton` configured with `UIButton.Configuration.filled()` for primary and `UIButton.Configuration.bordered()` for ghost, setting `configuration.baseBackgroundColor` / `.baseForegroundColor` to the accent color; wire navigation through the button's action/target.

- **WinUI 3**: Use `HyperlinkButton` with `NavigateUri` set from the `href` equivalent and `Content` set to the link text. For primary, set `Background` to the accent brush (e.g. via `AccentButtonStyle`); for ghost, leave `Background` transparent and set `BorderBrush`/`BorderThickness` to render the outline. Apply a `ControlTemplate` if the pill corner radius requires more than the default style provides.

