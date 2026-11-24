
The web default skin's fixed pixel size (see the React/Web Platform Note)
does not respond to the user's preferred text size. Native ports (SwiftUI, Compose, AppKit /
UIKit, WinUI 3) MUST use a scalable text style (e.g. Dynamic Type on Apple,
`sp`-based type scale in Compose) instead of a fixed point size, and the web
implementation SHOULD (and, per **default-deep-link-skin**, is meant to) express the size as `rem` rather than a raw pixel
value, so the label and glyph scale with the user's text-size setting.
Reduce Motion and Differentiate Without Color do not apply: the component
has no animation, and its affordance is carried by the `↗` glyph plus the
`apt-blue` token together, not by color alone.

