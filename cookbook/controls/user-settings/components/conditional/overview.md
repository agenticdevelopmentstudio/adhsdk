
Conditional renders one of two content branches — `children` when the `when` boolean is `true`, otherwise `fallback` — without adding a layout or container node around whichever branch is shown. It is a simple, stateless branching pattern. On React/Web, where JSX benefits from an explicit component for inline conditional rendering, this is a concrete `Conditional` component; SwiftUI, Compose, AppKit/UIKit, and WinUI 3 need no wrapper type at all — see Platform Notes for the native control-flow equivalent on each.

