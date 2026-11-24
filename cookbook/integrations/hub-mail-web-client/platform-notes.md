
- **SwiftUI**: Not applicable: Apple apps read the local mirror through `HubMailStore` and [adhsdk.ingredient.integrations.hub-mail-bridge](cookbook:e12914f0-3a3b-4fb7-ac0c-6332de37de4f).
- **AppKit / UIKit**: Not applicable, for the same reason.
- **Compose**: Not applicable: an Android client keeps a local mirror, as iOS does.
- **React/Web**: Source: `packages/web/packages/hub-mail/src/` (`hub-mail-client.ts`, `snapshot.ts`, `types.ts`). The host builds one client per signed-in session with `createHubMailClient({ fetchJson })` and hands it to the web Email App. The host's `fetchJson` adds any base-URL prefix its proxy needs and the stored bearer token.
- **WinUI 3**: A Windows host keeps a local mirror rather than reading this client: it pulls `/v1/sync/pull` into a local store and reads through a `MailClient`-shaped seam, as [adhsdk.ingredient.integrations.hub-mail-bridge](cookbook:e12914f0-3a3b-4fb7-ac0c-6332de37de4f) does on Apple. Only a WebView2-hosted web build would use this client, unchanged, with its own `fetchJson`.

