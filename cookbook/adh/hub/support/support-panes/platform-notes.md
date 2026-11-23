
- **SwiftUI**: Port each pane as a view over the same client, keeping the viewer free of edit controls.
- **Compose**: Use screens over the same repository and a read-only table.
- **React/Web**: The source platform: `packages/web/packages/features/support-access/` (a workspace package named `@adh-sdk/support-access`) and `packages/web/packages/features/adh-admin/src/panes/`. The `adh` package's `dist/` is rebuilt and committed after a change to its settings.
- **AppKit / UIKit**: As SwiftUI.
- **WinUI 3**: A page for each pane over the same client.

