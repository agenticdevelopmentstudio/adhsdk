
- **SwiftUI**: `CommitGraphLayout<ID: Hashable & Sendable>` in `AgenticDeveloperHubSDKCore` imports only `Foundation`; a view model holds it and appends each page of history, keeping the returned `Row`s beside its commits.
- **Compose**: A class holding a `MutableList<Slot?>` and an `Int` lane counter; `append` returns an immutable list of rows.
- **React/Web**: A class with an array of slots and a lane counter, kept in a ref across page loads so paging stays stateful.
- **AppKit / UIKit**: Identical to the SwiftUI note: the history list's graph column draws each `Row` in its cell, lane modulo its palette.
- **WinUI 3**: A class with a `List<Slot?>`; rows are records with value equality.

