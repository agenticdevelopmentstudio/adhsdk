
**Decision**: The component uses session state (`touched`) to track whether the user has manually edited the slug; once touched, the slug follows the title no further.
**Rationale**: This lets auto-generation from title edits continue until the user takes control, preserving intentional slug customization across later title rewrites. Touched state does not persist across remount; opening a new document (a different `key`) resets the behavior, matching the use case where documents are opened and closed within a session and users expect the slug to start fresh for each one.
**Approved**: pending

**Decision**: The component receives `verdict` as a prop rather than owning the slug-checking logic itself.
**Rationale**: This lets the host manage the checker (API call), debouncing, and stale-verdict dismissal, separating concerns and enabling shared truth: the host's Save button and the field's display both read the same verdict. The `useSlugAvailability` hook is exported for convenience, but the component does not require its use; hosts may provide verdicts computed any way they choose.
**Approved**: pending

**Decision**: The status message is rendered unconditionally in the DOM (even when its text is null) as an `aria-live="polite"` region.
**Rationale**: The region must exist before its content changes, or assistive technology has nothing to have observed the mutation on; mounting it together with its first content risks the first verdict update — often "Unavailable", the one most critical to hear — going unannounced. Status text prioritizes the reason over the default status label, so implementors can provide detailed feedback without duplicating the word "Unavailable".
**Approved**: pending

**Decision**: The slug input uses a smaller, monospace font to visually distinguish it from the human-readable title.
**Rationale**: This reinforces that the slug is a technical identifier (e.g., a URL path component) and may not match the title exactly.
**Approved**: pending

