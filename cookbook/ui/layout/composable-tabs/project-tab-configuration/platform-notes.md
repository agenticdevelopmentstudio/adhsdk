
- **AppKit / UIKit**: This is the source. `ProjectTabConfiguration` is a `Sendable` struct with one `let arrangement: LayoutNode?` and a memberwise `init(arrangement:)`. `ComposableTabsWindowController.tabConfiguration` produces it and `adopt(_:)` applies it; `ProjectWindowManager` moves it between windows when a project window is shown or becomes key.
- **SwiftUI**: The same plain struct works unchanged; a SwiftUI host would pass it through an environment value or an observable model rather than between window controllers.
- **Compose**: A Kotlin `data class ProjectTabConfiguration(val arrangement: LayoutNode?)` with `val` fields gives the same immutable value.
- **React/Web**: A frozen object `{ arrangement }`, typed `Readonly<{ arrangement: LayoutNode | null }>` in TypeScript.
- **WinUI 3**: A C# `record ProjectTabConfiguration(LayoutNode? Arrangement)`.
