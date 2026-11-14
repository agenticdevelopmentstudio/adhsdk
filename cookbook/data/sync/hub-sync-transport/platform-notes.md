
- **SwiftUI**: Source platform, shared by macOS and iOS: `HubSync/ADHSyncTransport.swift`, a `Sendable` struct conforming to `SyncTransport`, built for both destinations.
- **Compose**: Implement the engine's transport interface over a Ktor or OkHttp client with `kotlinx.serialization`, and map HTTP 401 and 410 to the same two errors. Rethrow `CancellationException` unchanged, as coroutines require.
- **React/Web**: Not needed: the web app reads through the hub API and keeps no local mirror, so it has no sync engine to feed.
- **AppKit / UIKit**: The same Swift type serves both; nothing in it touches UI.
- **WinUI 3**: Implement the transport interface over `HttpClient` with `System.Text.Json`, mapping 401 and 410 the same way and letting `OperationCanceledException` through.

