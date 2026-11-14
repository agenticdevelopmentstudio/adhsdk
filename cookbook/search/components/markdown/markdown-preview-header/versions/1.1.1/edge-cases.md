
- **Empty or missing title**: Falls back to "Untitled" for a falsy `hit.title` (empty string, `null`, or `undefined`); this is a falsy check, not a trim, so an all-whitespace title is truthy and renders as literal whitespace instead of falling back.
- **Title attribute vs. displayed text**: The h3 `title` attribute always mirrors the raw `hit.title` value, even when the visible text has fallen back to "Untitled" — a missing title therefore produces an empty tooltip attribute alongside the fallback text.
- **Null or undefined author fields**: Author slug is always available as fallback; if displayName is null, undefined, or empty/whitespace after trim, fallback to slug with @ prefix.
- **Null, undefined, or empty updatedAt**: Date section is entirely omitted; no placeholder or default date is shown.
- **Long title wraps, does not truncate**: The h3 is allowed to shrink below its content width within the flex container (`min-w-0`), but the source applies no ellipsis, `overflow-hidden`, or line-clamp to it — a title exceeding available space wraps onto multiple lines instead. The full (raw) title is nonetheless available via the `title` attribute for hover-tooltip display, independent of how the visible text wraps.
- **Per-kind renderer fallback**: kindRendererFor returns a neutral default renderer for unknown kinds; previewExtra may return null or undefined for kinds without extra content — both render nothing.
- **Missing public route**: Link is not rendered when `hit.publicRoute` (a string) is empty; href and route values are independent — href may be a well-formed string even when route is empty.
- **Non-locale-aware date formatting**: `formatDate` always renders dates using `en-US` formatting regardless of the active UI locale (see Compliance: locale-aware-formatting).
- **Time-zone-dependent day for date-only input**: Because `formatDate` parses a date-only ISO string as UTC midnight and formats it with no `timeZone` option, the rendered calendar day depends on the viewer's local time zone — any zone west of UTC displays the day before the ISO date. See header-012.

