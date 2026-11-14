
- **No `stats`**: `stats?.map(...)` no-ops, so a card with only `children` and/or a
  `footnote` renders fine (`stats` is optional).
- **No `link` and no `actions`**: the InfoPanel actions slot is omitted entirely
  (the header shows just icon + title).
- **`actions` without `link`**: the slot renders just the extra controls (e.g. a
  monitor card's live status word), right-justified by InfoPanel.
- **`footnote` guard is `!= null`**: `null`/`undefined` hide the footnote; an empty
  string (`""`) is *not* null and WOULD render an empty caption — pass `undefined` to
  hide, not `""`.
- **Rows + children + footnote together**: order is always rows → children → footnote
  within the one `gap-2.5` stack; `children` is the escape hatch for anything the
  declarative `stats[]` can't express (e.g. the status Errors card's live error line
  with a `StatusDot` and a count).
- **Always content-sized**: it never passes `scroll` to InfoPanel, so a long stat list
  grows the card rather than scrolling; use InfoPanel directly if scroll is needed.
- **`icon` is decorative**: InfoPanel marks the leading glyph `aria-hidden`, so the
  card's accessible name is the `title` alone — see **title-as-accessible-name**.
- **Per-stat `tone`**: omitted `tone` falls back to StatRow's `neutral`; the card adds
  no tone of its own.

