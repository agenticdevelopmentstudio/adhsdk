
- **Empty title, slug not touched**: If title is empty string and slugify returns empty, slug input value is empty; `useSlugAvailability` does not trigger a check when its `slug` argument is empty, so no verdict changes for an empty slug.
- **Null reason in verdict**: If verdict.reason is not present or is null, status message displays the default text for the status (e.g., "Available"), not null or "undefined".
- **Verdict for stale slug**: `useSlugAvailability` stamps each answer with the slug (and optional `subject`) it was asked about and discards an answer whose stamp no longer matches the current question. This discarding is the hook's responsibility, not the component's: the component itself has no notion of a verdict's age — it only ever receives and displays whichever verdict its `verdict` prop currently holds, whether that verdict comes from `useSlugAvailability` or from a caller-supplied source.
- **Checker throws**: If the slug availability checker passed to `useSlugAvailability` throws, the hook's verdict reverts to idle; the component does not display a distinct error state for this case, since it cannot distinguish "the network is down" from "the slug is taken."
- **Remount with same document ID, different slug**: If the component is remounted (key changes), the touched state resets to false and slug begins following title again.
- **Title and slug both disabled**: Inputs remain readable; their values are displayed but not editable.
- **Verdict arrives after user stops editing slug**: Status message updates to reflect new verdict even after user moves focus away; aria-live region ensures announcement.
- **Very long title**: Slug input is flex-1, so it grows to fill available space; title input grows equally. Very long titles are not truncated by the component itself (handled by input or container constraints).
- **Verdict reason longer than status slot**: Reason text is displayed in full without truncation; overflow behavior is inherited from container (may wrap or scroll, depending on layout).

