
| State | Appearance change |
|-------|------------------|
| Default | @ glyph and star both visible; no drop-shadow bloom; popover (`.pc-rm-tip`) hidden (`opacity: 0`, `visibility: hidden`) |
| Hover (link) | Companion CSS (`registry-mark.css`) applies `drop-shadow(0 0 4px currentColor)` to the @ glyph and a matching gold bloom (`--pc-rm-adh-gold`) to the star; the popover becomes visible |
| Focus (link, `:focus-visible`) | Same bloom as Hover, plus a `1px` outline on the link (`.pc-rm-link:focus-visible`); the popover becomes visible |
| Focus with popover open | Popover (`.pc-rm-tip`) is visible and keyboard-reachable, and stays open via the companion CSS's `:has(:focus-visible)` selector (plus a pointer bridge, `.pc-rm-tip::after`) even once focus moves onto a link inside it — see **popover-visible-on-focus-or-hover** |

