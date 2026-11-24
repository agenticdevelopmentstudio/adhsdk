
Applicable: the component renders one hardcoded, non-localizable, user-facing string — the close button's `aria-label="Dismiss"` (see **label-close-button**). The "×" close glyph (see **render-close-glyph**) is a symbol, not translatable text, and needs no localization. `children` is caller-supplied content and localizing it is the caller's responsibility.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded, no prop) | "Dismiss" | Close button `aria-label` |

The source exposes no prop to override or localize this string. The **Hardcoded English aria-label** Design Decision below records that other-platform implementations SHOULD make it an optional, localizable label rather than hardcoding it, since the source itself does not provide that hook.

