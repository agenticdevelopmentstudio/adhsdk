
`UserDefaultsThemeStorage` is the `ThemeStorage` implementation for a host that has no settings system of its own. `ThemeStorage` is a `@MainActor`, class-bound protocol with three members: `customThemes` (an array of `ColorTheme`), `activeThemeID` (an optional `String`) and `onExternalChange` (an optional closure). This class keeps the first two in a `UserDefaults` domain and uses `UserDefaults.didChangeNotification` to fire the third when something other than this object moved them.

The source comment gives the reason it exists: a host with a settings system supplies its own `ThemeStorage` instead of inheriting a preference location, and plenty of hosts (a single-window utility, an iOS app whose only preference is the theme) have none, so the same short implementation lives here once. The keys and the JSON encoding match what the AgenticDeveloperHubSDK host writes through its own settings system, so a host that later swaps this class for its own conformer finds the saved themes where this class left them.

Built-in themes are never stored here; the `ThemeStorage` comment states that `ThemeStore` concatenates them at read time, so an empty storage still yields a full catalog. The model type it stores is described by the `ColorTheme` recipe.

