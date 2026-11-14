
**Decision**: The public link renders only when `hit.publicRoute` is a non-empty string; the `href` prop is always passed through, independent of `publicRoute`.
**Rationale**: A hit with no public route has no public page to link to, and `href` may still be a well-formed string even when there is no route — checking `publicRoute` rather than `href` avoids rendering a link to nowhere. The two are separate because the URL space belongs to the host: the host builds the finished `href` with its own `documentHref` (the link seam in the search package's `types.ts`), and this component only decides whether a public page exists. The two props must therefore agree, and the host is the one that keeps them in step.
**Approved**: pending

**Decision**: The kind badge and optional extra section are sourced from the `kindRendererFor` per-kind renderer map rather than branched inline in this component.
**Rationale**: A new kind can be added with a single map entry, without editing this component; unknown kinds fall back to a neutral default renderer so an unexpected value degrades gracefully.
**Approved**: pending

**Decision**: "Untitled" is rendered via a falsy check rather than a trim (see **title-fallback**).
**Rationale**: Ensures the header always displays a title, improving the experience when metadata is incomplete.
**Approved**: pending

**Decision**: `displayName` is preferred over `slug` for author attribution; `slug` (with an `@` prefix) is used only when `displayName` is absent or empty after trimming.
**Rationale**: A display name is more readable than a slug; the `@`-prefixed slug is a familiar fallback convention when no display name is available.
**Approved**: pending

**Decision**: The summary is trimmed and excluded when whitespace-only.
**Rationale**: Prevents an empty or blank-looking summary paragraph from rendering.
**Approved**: pending

**Decision**: The public link uses `focus-visible` rather than `:focus` for its focus ring.
**Rationale**: Shows the focus ring only on keyboard navigation, not on mouse click, following web accessibility best practice.
**Approved**: pending

**Decision**: Date-only `updatedAt` strings are formatted with `formatDate`, which passes no `timeZone`, so the day shifts back by one in zones west of UTC (see **optional-date**). This is deliberate debt, not a goal; a port MAY format with `timeZone: 'UTC'` and show the ISO calendar day.
**Rationale**: `formatDate` is a shared helper used by the result row as well, and the source has not changed it; the spec records what the source does rather than silently specifying new behavior.
**Approved**: pending
