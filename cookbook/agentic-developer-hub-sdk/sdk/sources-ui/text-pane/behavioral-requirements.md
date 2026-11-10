
- **initialize-with-editability**: The component MUST initialize with an `editable` parameter that determines whether text editing is allowed (true = editable, false = read-only).
- **provide-editability-property**: The component MUST provide an `isEditable` property that reads and modifies the underlying text view's edit mode at runtime.
- **report-text-changes**: The component MUST fire the `onTextChange` callback with the current plain-text content whenever the user edits the text. The callback receives the complete current string, not a delta.
- **silent-programmatic-set**: Setting the `text` property MUST NOT trigger the `onTextChange` callback. Programmatic text assignment exists to enable controllers that render from `onTextChange` to update the pane without re-entrancy loops.
- **provide-text-property**: The component MUST provide a `text` property that reads and sets the pane's plain-text content. Reading returns the complete string; empty panes return an empty string (never null).
- **support-attributed-text**: The component MUST support reading and setting attributed (styled) text via `attributedText` (read-only) and `setAttributedText(_:)` (write).
- **support-focus**: The component MUST provide a `focus()` method that moves keyboard focus to the underlying text view and returns a boolean indicating success. A pane without focus does not receive keystrokes because the internal text view is private.
- **support-theme**: The component MUST accept a `SemanticPalette` via `applyTheme(_:)` to customize colors and font. Theme application MUST update: background, text foreground, cursor color, selection background and selection foreground, and code font (not body font).
- **disable-smart-substitutions-ios**: On iOS, the component MUST disable `autocorrectionType`, `smartQuotesType`, and `smartDashesType` to prevent automatic text transformations inappropriate for code/markdown content.
- **disable-smart-substitutions-macos**: On macOS, the component MUST disable automatic quote substitution, dash substitution, spelling correction, and text replacement to prevent automatic text transformations.
- **allow-undo-macos**: On macOS, the component MUST support the undo system (`allowsUndo = true` on the text view).
- **preserve-default-undo-ios**: On iOS, the component MUST NOT disable or replace the text view's `undoManager`; the platform's default undo behavior (e.g. shake-to-undo, hardware Cmd+Z) MUST remain available.
- **use-plain-text-mode**: The component MUST operate in plain-text mode. Rich text editing, markdown parsing, and styled rendering are explicitly not in scope.
- **scroll-vertically**: The component MUST support vertical scrolling. On macOS, the scroll view provides this; on iOS, the text view provides built-in scrolling.
- **hide-scrollers-macos**: On macOS, the scroll view MUST use overlay scrollers that auto-hide when not in use. The scroll view MUST have no visible border.
- **bounce-vertically-ios**: On iOS, the text view MUST bounce when scrolled past the content end.
- **use-8pt-insets**: The component MUST apply 8pt insets (edges) around the text content, matching the document-surface intent rather than the tighter 6pt used by scratch/quick-note style inputs.
- **enable-find-bar-macos**: On macOS, the component MUST enable the text view's built-in find bar (`usesFindBar = true`, `isIncrementalSearchingEnabled = true`) so Cmd+F opens in-pane search. The iOS variant exposes no equivalent — see the **Design Decisions** entry on this asymmetry.

