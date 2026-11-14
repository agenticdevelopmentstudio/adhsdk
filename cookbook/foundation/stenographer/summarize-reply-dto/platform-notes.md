
- **SwiftUI**: Hold the reply in a view model: show the summary when `summary` is set, and when `error` is set show it as an inline message, such as a banner or alert, next to the session. In this repository the equivalent display is `StenographerSummarizing`, whose error text feeds the sessions list's error banner.
- **Compose**: Use a Kotlin `data class` with `@Serializable`, `summary` and `error` nullable and defaulting to null; the UI shows `error` when present, else the summary. An Android port replaces XPC with a bound service or an HTTP call.
- **React/Web**: Use a TypeScript interface with `summary?` and `error?`, or a discriminated union that enforces the one-of rule the Swift type leaves to convention.
- **AppKit / UIKit**: An AppKit view shows `error` in a label or `NSAlert` after the summarize action; XPC is macOS-only, so an iOS port would carry the reply over HTTP, where `SummarizeDaemonFailure` plays this role.
- **WinUI 3**: Use a C# `record SummarizeReply(string SessionId, string? Summary = null, string? Error = null)` serialized with `System.Text.Json`; value equality replaces `Equatable`. Replace XPC with a named pipe or loopback HTTP, and show `Error` in a `TextBlock` or `InfoBar` bound to a view model that implements `INotifyPropertyChanged`.

