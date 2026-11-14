
- **SwiftUI**: `openWindow(id:value:)` with a value-keyed `WindowGroup` gives one window per value; the persisted list replaces scene restoration when the app restores on its own terms.
- **Compose**: Desktop: a `mutableStateMapOf<String, WindowState>` rendered as `Window`s, persisted to preferences.
- **React/Web**: Not applicable to a single-page app; an Electron host keeps a `Map<string, BrowserWindow>` and the list in its store.
- **AppKit / UIKit**: AppKit: `KeyedWindowSet<Controller: AnyObject>` in `AgenticDeveloperHubSDKMacOS`, over any window controller type. UIKit: one `UIScene` per key, keyed through `NSUserActivity`.
- **WinUI 3**: A `Dictionary<string, Window>` with the list in `ApplicationData.LocalSettings`.

