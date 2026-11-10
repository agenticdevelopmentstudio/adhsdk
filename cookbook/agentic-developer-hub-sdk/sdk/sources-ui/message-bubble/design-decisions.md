
**Decision**: The streaming caret uses the block character U+258B (▋), appended directly into the same attributed/text string as the message rather than as a separate animated element.
**Rationale**: A static, easily measured character fits inline with the text and gives visual feedback that a message is still composing without requiring animated state changes; because it is part of the same string, the measurement pass automatically includes it, so the caret can never overhang the bubble.
**Approved**: pending

**Decision**: Timestamps use one locale-aware rule everywhere: derive the pattern from the locale's own hour-cycle template (`toLocaleTimeString` on Web; `DateFormatter.dateFormat(fromTemplate: "jmm", ...)` on macOS) and widen a single-digit hour field to two digits, leaving the separator, ordering, and AM/PM marker as the locale wrote them.
**Rationale**: The locale, not the implementation, decides the hour cycle and ordering; the two-digit hour width is the one fixed constraint Web and macOS already share. iOS's current hard-coded `"HH:mm"` format does not follow this rule — it forces a 24-hour clock on every reader regardless of locale — and is a known non-conformance to bring in line with macOS's approach, not a second valid behavior.
**Approved**: pending

**Decision**: The failure reason is rendered as appended text (below the message, in caption font and danger color) rather than as a separate element or icon.
**Rationale**: Provides context — what went wrong — beyond the visual border cue; the reason itself is always caller-provided via `deliveryStatus.failed(reason)`, so the component never invents wording.
**Approved**: pending

**Decision**: A theme that declares no bubble fill (alpha ≤ 0.001) is treated as "no bubble": padding and corner radius are zeroed and the message renders as a flat transcript line.
**Rationale**: Avoids invisible boxes in themes like `terminal` or `crt-monitor` that deliberately omit bubble styling; the geometry (padding, radius) is treated as part of the bubble, so a theme opting out of fill also opts out of the geometry built around it.
**Approved**: pending

**Decision**: The avatar slot is always rendered, even when the sender has no avatar image, and the sender's name is rendered only into the accessibility tree via a visually-hidden element.
**Rationale**: Keeps the left-edge gutter aligned across every message in a transcript that mixes senders with and without avatars; a conditionally-rendered avatar div would shift the text column depending on the sender. Hiding the sender name visually (rather than omitting it) still exposes it to screen readers without introducing a visible name into themes that were drawn without one.
**Approved**: pending

**Decision**: When rich content includes images, the Web implementation withholds the entire bubble render — including the message text — until every image has finished loading.
**Rationale**: Matches how `useAllImagesLoaded` gates the component today and keeps image layout from reflowing the bubble after first paint. This is the required behavior (see **rich-content-load-gating**), not an incidental gap; callers must be prepared for the component to render nothing while content is loading, including the case where it unmounts before loading completes.
**Approved**: pending

**Decision**: The optional bubble border is applied only when a theme explicitly *declares* a border role (`palette.declares(borderRole)`), not merely when resolving that role produces a visible color.
**Rationale**: Every role resolves to *some* color when a theme omits it, so checking the resolved color alone would draw a hairline border around every bubble in every theme; checking declaration instead limits the border to themes (`charcoal`, `techy`, `fishlamp`, `mikefullerton`) that opted in.
**Approved**: pending

