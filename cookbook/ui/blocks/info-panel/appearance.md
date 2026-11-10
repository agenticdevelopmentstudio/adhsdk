
Content-sized card (default):

```
┌───────────────────────────────────────────────┐
│ [◆] Title  12          ⟨center⟩        ⟨actions⟩│  header, min-height 41
├───────────────────────────────────────────────┤
│ content sized to its children (no scroll)       │
└───────────────────────────────────────────────┘
```

Fill + scroll (`scroll`):

```
┌───────────────────────────────────────────────┐
│ [◆] Title  128         ⟨center⟩        ⟨actions⟩│
├───────────────────────────────────────────────┤
│ rows…                                         ▲ │
│ rows…                                         █ │  body scrolls; panel flexes to fill
│ rows…                                         ▼ │
└───────────────────────────────────────────────┘
```

- **Corner radius**: 10px on the outer container; content clips to it (the outer
  overflow is hidden).
- **Border**: 1px, theme border color; the same color underlines the header as a
  divider.
- **Background / Foreground**: theme surface and text colors, consistent across
  light and dark.
- **Header height**: minimum 41px (`INFO_PANEL_HEADER_HEIGHT`), so sibling panels
  on a rail line up even when their content differs; a flex child can shrink
  below its content in scroll mode so the body — not the panel — scrolls.
- **Header text**: title is small, semibold, non-wrapping; count is dim, 11px
  monospace.
- **Body padding**: 12px vertical / 16px horizontal by default in card mode; 8px
  top / 16px sides / 10px bottom by default in scroll mode; either default is
  fully replaced by `bodyPadding` when supplied.
- **Outer layout**: flex `0 0 auto` (card, content-sized) or `1 1 0` (scroll,
  fills its track).
- Styled entirely with theme tokens; no raw colors, no forced overrides. See the
  **React/Web** platform note for the exact utility classes.

