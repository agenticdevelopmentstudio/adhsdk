
- **SwiftUI**: Not applicable: iOS reads `HubMailStore` directly and has no mail RPC to answer.
- **AppKit / UIKit**: Source platform: `packages/apple/AgenticDeveloperHubSDK/HubMailBridge/`, macOS only. The host builds `HubMailService.live(databaseURL:deviceId:)` once at launch, shows its `account` in the accounts settings, calls `start()` so a stored login reconnects, and hands `MailClient.routed { source == .hub ? live.service.client : daemonClient }` to the mail browser and the Email App. The Integrations settings panel keeps the daemon's client, because it administers the direct worker.
- **Compose**: Not applicable: an Android client reads its mirror directly, as iOS does.
- **React/Web**: Not applicable: the web app reads the hub API directly and has no local RPC.
- **WinUI 3**: Not applicable until a Windows host shares one mail UI between two sources; it would follow this shape.

