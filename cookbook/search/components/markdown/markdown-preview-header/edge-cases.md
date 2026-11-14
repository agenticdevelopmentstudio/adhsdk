
- **Empty or missing title**: Falls back to "Untitled" — see **title-fallback**, including the whitespace-only case.
- **Title attribute vs. displayed text**: The `title` attribute is independent of the visible fallback text — see **title-attribute** (empty string gives an empty attribute; `null` or `undefined` gives none).
- **Null or undefined author fields**: Author slug is always available as fallback; if displayName is null, undefined, or empty/whitespace after trim, fallback to slug with @ prefix.
- **Null, undefined, or empty updatedAt**: Date section is entirely omitted; no placeholder or default date is shown.
- **Long title wraps, does not truncate**: The h3 is allowed to shrink below its content width within the flex container (`min-w-0`), but the source applies no ellipsis, `overflow-hidden`, or line-clamp to it — a title exceeding available space wraps onto multiple lines instead. The raw title stays available through the `title` attribute (see **title-attribute**).
- **Per-kind renderer fallback**: kindRendererFor returns a neutral default renderer for unknown kinds; previewExtra may return null or undefined for kinds without extra content — both render nothing.
- **Missing public route**: Link is not rendered when `hit.publicRoute` (a string) is empty; href and route values are independent — href may be a well-formed string even when route is empty.
- **Unparseable updatedAt**: `formatDate` returns `''` for a string `new Date` cannot parse, so no date text renders — not "Invalid Date" (see **optional-date**).
- **Non-locale-aware date formatting**: `formatDate` always renders dates using `en-US` formatting regardless of the active UI locale (see Compliance: locale-aware-formatting).
- **Time-zone-dependent day for date-only input**: Because `formatDate` parses a date-only ISO string as UTC midnight and formats it with no `timeZone` option, the rendered calendar day depends on the viewer's local time zone — any zone west of UTC displays the day before the ISO date. See header-012 and header-028.

