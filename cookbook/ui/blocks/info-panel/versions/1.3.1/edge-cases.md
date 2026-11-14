
- **Non-string title**: when `title` is a node (not a string) and no `ariaLabel` is
  given, the region has no accessible name — hosts SHOULD pass `ariaLabel` in that
  case.
- **Actions without center**: the actions container is given `ml-auto` only when
  `center` is absent, so it still hugs the right edge without a center spacer.
- **Count exactly 0**: treated as "nothing to show" and hidden (only `> 0` renders),
  so an empty list's panel doesn't show a "0".
- **Scroll flex child**: `min-h-0` is applied in scroll mode so the panel can shrink
  below its content inside a flex parent and let the body — not the panel — scroll.
- **Body padding override**: `bodyPadding` fully replaces the mode default; hosts
  needing edge-to-edge content (e.g. a table) pass `bodyPadding="0"`.
- **maxHeight with card mode**: a content-sized card given a `maxHeight` will clip via
  the outer `overflow-hidden`; use `scroll` to make the body scroll within that cap.

