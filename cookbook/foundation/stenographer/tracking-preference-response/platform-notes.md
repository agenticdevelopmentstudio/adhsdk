
- **SwiftUI**: Not used here; a port would bind a `Toggle` to `enabled` and treat `outcome` as an opaque string.
- **Compose**: a Kotlin `data class TrackingPreferenceResponse(val enabled: Boolean, val disabledMarkerPresent: Boolean, val outcome: String)` with a serialization annotation; decode `outcome` as a plain string.
- **React/Web**: a TypeScript interface of two booleans and a string; narrow `outcome` with a union plus a fallback for unknown values.
- **AppKit / UIKit**: Bind an `NSSwitch` to `enabled`: it posts `{"enabled": Bool}` and reads this reply to confirm the new state. The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/TrackingPreferenceResponse.swift`: a `public struct` conforming to `Encodable` and `Sendable` with a public memberwise `init`.
- **WinUI 3**: Use a C# `record TrackingPreferenceResponse(bool Enabled, bool DisabledMarkerPresent, string Outcome)` with `System.Text.Json` attributes matching the daemon's property names; bind a `ToggleSwitch` on the settings page to `Enabled` and treat `Outcome` as an opaque string with a fallback for unknown values.

