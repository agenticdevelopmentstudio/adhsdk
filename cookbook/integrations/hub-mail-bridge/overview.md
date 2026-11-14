
The macOS mail UI (the mail browser, the Email Desktop App and the Integrations settings panel) talks to mail through one seam: a `MailClient` built over a transport that carries an encoded `MailRequest` ([adhsdk.ingredient.integrations.service.mail-rpc](cookbook:fc9671be-170c-436e-9628-892624952191)) and brings back a `MailResponse`. The direct Gmail worker answers that RPC inside `temporald`. `HubMailBridge` answers the same RPC from the hub mail mirror ([adhsdk.ingredient.integrations.hub-mail](cookbook:a6442464-e17d-451e-b47a-3be23a2dc753)) instead, so the host switches a window between hub and direct mail by handing it a different `MailClient`, and none of the UI changes.

It lives in its own framework, `AgenticDeveloperHubSDKHubMailBridge` (`HubMailBridge/`), built for macOS and iOS, because it is the one place that needs both sides: the mail RPC types from `AgenticDeveloperHubSDKMail` and the hub mirror from `AgenticDeveloperHubSDKHubMail`. Neither of those links the other. It also uses HubAuth, HubSync, Sync, Database, the hub client, and the foundation framework `AgenticDeveloperHubSDK` (for `HTMLText`); it does not link Core or the macOS-only Integrations. An iOS host may read `HubMailStore` directly instead of linking it.

What it does with each request:

- **Mailbox reads** (accounts, labels, messages, one message, a thread) are answered from `HubMailStore`, mapped into the RPC's types.
- **Label writes** (modify labels, move) go to the hub's `modify_labels` integration action, and the hub's worker applies them in Gmail. The bridge then writes the same change into the local mirror, because the hub action leaves the hub's own row as it is until the worker's next sync.
- **Sync now** runs a pull.
- **Administration** (the OAuth client, signing accounts in and out, sync settings) is refused: on the hub path those are managed on the hub.

`HubMailService` keeps a bridge open while a hub identity is signed in. Its `client` is one stable `MailClient` for the app's lifetime: it answers through the current bridge when connected and refuses with a sign-in message otherwise, so windows can hold it from launch. Sign-in opens the mirror and pulls; sign-out purges it. `HubMailService.live` ties the service to a `HubAccount` over one shared session, so signing in from the accounts settings opens hub mail. `MailClient.routed` (in the Mail framework, with `MailSource`) picks the direct or hub client per request, which is how a host offers a source switch.
