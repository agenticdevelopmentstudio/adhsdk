
- **Empty or missing data**: a domain with neither key reads as no themes and a nil active id. MUST.
- **Empty array write**: writing `[]` stores the text `[]` and the key stays present. MUST.
- **Corrupt stored themes**: undecodable data reads as an empty array and is left in place; the next write of `customThemes` overwrites it. An empty catalog still yields every built-in theme. MUST.
- **Partially valid stored themes**: `ColorTheme`'s decoder defaults the optional fields (`isBuiltIn`, `isImported`, `attribution`, `roleOverrides`, `typography`, `terminal`, `project`) when absent but throws when a required field (`id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `selection`, `ansi`) is missing; this class treats any decode throw as no themes at all, so one element missing a required field hides every other stored theme. This is current behavior, recorded as known debt in the Design Decisions, not a requirement.
- **Encode failure** (MUST): see `encode-failure`; the stored catalog is unchanged.
- **Unknown or empty active id**: any string, including the empty string, is stored unchanged; the setter does not validate. MUST.
- **Clearing the active id**: writing nil removes the stored value, and the last-seen id becomes nil first, so the removal does not report as external. MUST.
- **Foreign write of the same value**: does not fire the callback. MUST.
- **Several writes, one notification**: fires at most once. MUST.
- **Unrelated key changes**: the notification arrives but the comparison finds no difference, so no callback. MUST.
- **Notification timing**: the source comments describe delivery both as "a later turn of the run loop" and as synchronous when post and observer queue are both main; the record-before-write ordering is what makes both safe (see `themes-write-records-first`).
- **Concurrent access**: the class is `@MainActor`, so its own reads, writes and callback are serialized on the main actor; the compiler enforces this. A write from another process or thread into the same domain is the foreign-change case.
- **Release during a pending notification**: the observer holds `self` weakly and `deinit` removes it; a notification queued before release finds no object and does nothing. MUST.
- **Two instances over one domain**: each reports the other's writes as external (`multiple-instances`), because the class has no way to tell them apart. MUST.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.
- **Offline or disconnected state**: not applicable; the class does no network access. An iCloud-backed sync that arrives later is just another foreign change.

