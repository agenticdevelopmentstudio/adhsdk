
- **Null and empty input**: With no `messages` prop the component MUST use the default wording built from `noun`; with `saveError` null or an empty string the save-failed line MUST NOT render (the shared error text renders nothing for a falsy error).
- **Boundary values**: A `noun` of an empty string yields notices like "This  no longer exists."; the source does not guard it, and callers SHOULD pass a non-empty noun.
- **Concurrent access**: The conflict state is the concurrency case: a conflict warning MUST replace the changed notice, and Overwrite MUST be disabled while a save is in flight so a second save cannot start from the warning. Save from the bar is disabled while saving for the same reason.
- **Error states**: A failed save shows `Save failed: ` plus the error inline and keeps the bar usable, in place of a browser alert; a missing document shows the gone notice while the draft is kept, as the hook's `gone` documents.
- **Offline or disconnected state**: The component has no network access of its own. A save that fails for network reasons arrives as `saveError`, and the component shows it with no retry control of its own; the user can press Save again while the document is still dirty.
- **Several notices at once**: Gone, changed-elsewhere and save-error MAY show together; they wrap within the leading area.

