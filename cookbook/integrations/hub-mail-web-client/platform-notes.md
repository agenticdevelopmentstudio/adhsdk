
- **SwiftUI**: Not applicable: Apple apps read the local mirror through `HubMailStore` and [adhsdk.ingredient.integrations.hub-mail-bridge](cookbook:e12914f0-3a3b-4fb7-ac0c-6332de37de4f).
- **AppKit / UIKit**: Not applicable, for the same reason.
- **Compose**: Not applicable: an Android client keeps a local mirror, as iOS does.
- **React/Web**: Source: `packages/web/packages/hub-mail/src/` (`hub-mail-client.ts`, `snapshot.ts`, `types.ts`). The host builds one client per signed-in session with `createHubMailClient({ fetchJson })` and hands it to the web Email App. whatsnow's `fetchJson` prefixes `/api` (its Next rewrite forwards to the backend with no prefix) and adds the stored bearer token.
- **WinUI 3**: Not applicable until a Windows host exists; it would keep a local mirror.

