
- **SwiftUI**: Source platform for macOS and iOS: `packages/apple/AgenticDeveloperHubSDK/HubMail/`, one framework built for both, over GRDB and `BoundedDatabase`. A SwiftUI or UIKit screen reads `HubMailStore` after each `pulledBatch` event.
- **Compose**: Mirror with Room or SQLDelight tables of the same columns, filled by the Kotlin sync engine; page with the same `(internal_date, id)` keyset. Send through the hub client's action call.
- **React/Web**: No local mirror: the web app reads the same two tables through the hub API and sends through the same action route.
- **AppKit / UIKit**: The macOS mail browser reads through an adapter that turns these records into the Integrations framework's mail types, so the same browser shows hub or direct mail.
- **WinUI 3**: Mirror with `Microsoft.Data.Sqlite` tables of the same columns; page with the same keyset; send through the hub client.

