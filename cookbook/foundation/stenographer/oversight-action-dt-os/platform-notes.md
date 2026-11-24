
- **SwiftUI**: Not used (AppKit only).
- **Compose**: Kotlin data classes with `kotlinx.serialization`; the `blocked` factory is a companion function; the control's enabled state is `target.actionable && injector.supports(target.termProgram)`.
- **React/Web**: TypeScript interfaces; the act call is a `POST` through `fetch`; a browser cannot inject into a terminal, so a web client only displays `reason` and the target.
- **AppKit / UIKit**: A finding row binds its action button's `isEnabled` to `actionable` and the injector's terminal support, with `reason` as the tooltip. The structs are `Codable`, `Sendable`, `Equatable` with a static factory; the injection itself uses the app's Automation grant, which is app-side and not in this file.
- **WinUI 3**: Use C# records with `System.Text.Json` and a static `Blocked(int findingId, string reason)` factory on the target record; a `Button` with `IsEnabled` bound through `x:Bind` to `Actionable` and a terminal-support check; `HttpClient.PostAsync` calls the act route after injection succeeds; the injection itself has no direct Windows equivalent of Apple's Automation, so a port needs a console or terminal input API (for example `SendInput` against a Windows Terminal window, or `WriteConsoleInput`) decided separately.

