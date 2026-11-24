
- **SwiftUI**: Same type as AppKit / UIKit below; nothing in it is SwiftUI-specific.
- **Compose**: Implement the engine's transport interface over the API layer's client (Ktor or OkHttp) with `kotlinx.serialization`, and map the API layer's failure type, not raw HTTP status codes: unauthorized to `unauthorized`, resync-required to `resyncRequired`, http(code) to `invalidResponse(code)`, transport(message) to `transport(message)`, and any coding or other error to `transport` with its description. Rethrow `CancellationException` unchanged, as coroutines require.
- **React/Web**: Not needed: the web app reads through the hub API and keeps no local mirror, so it has no sync engine to feed.
- **AppKit / UIKit**: Source: `packages/apple/AgenticDeveloperHubSDK/HubSync/ADHSyncTransport.swift`, a `Sendable` struct conforming to `SyncTransport`, built for both macOS and iOS. It is UI-agnostic Swift.
- **WinUI 3**: Implement the transport interface over the API layer's client (`HttpClient`) with `System.Text.Json`, mapping the API layer's failure type with the same five mappings as Compose (the four named failures plus coding or other errors to `transport`) and letting `OperationCanceledException` through.

