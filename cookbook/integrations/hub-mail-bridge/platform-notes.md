
- **SwiftUI**: Not applicable: iOS reads `HubMailStore` directly and has no mail RPC to answer.
- **AppKit / UIKit**: Source platform: `packages/apple/AgenticDeveloperHubSDK/HubMailBridge/`, macOS only. The host builds `HubMailBridge(store:writeLabels:syncNow:)` once per signed-in hub session and hands `bridge.client` to `MailBrowserViewController(client:)` and the settings panel in place of the daemon's client.
- **Compose**: Not applicable: an Android client reads its mirror directly, as iOS does.
- **React/Web**: Not applicable: the web app reads the hub API directly and has no local RPC.
- **WinUI 3**: Not applicable until a Windows host shares one mail UI between two sources; it would follow this shape.

