
The `↗` glyph is directional and MUST be mirrored (or swapped for a start-pointing
equivalent, e.g. `↖`) in right-to-left layouts — an unmirrored trailing arrow
points the wrong way for an RTL reader. Native ports SHOULD key this off the
platform's layout-direction API (Apple's `layoutDirection`/
`UserInterfaceLayoutDirection`, Compose's `LocalLayoutDirection`, WinUI 3's
`FlowDirection`); web SHOULD gate a logical transform on `dir="rtl"`. The
component itself has no other user-facing strings — the label is the
consumer's `children` — but a caller that adds a visually-hidden "opens in a
new tab" hint (see Accessibility) owns that string and is responsible for
localizing it; the component does not provide or externalize it.

