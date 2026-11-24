
- **Mark omitted**: When `mark` is undefined, no image element renders; headline and tagline render as expected. See hero-011.
- **Children omitted**: When `children` is undefined, CTA/trust/status sections are not rendered; headline and tagline render as expected. See hero-012.
- **Empty headline or tagline**: No validation in component; empty or whitespace-only strings render as empty h1/p elements. Host is responsible for providing non-empty content. See hero-013.
- **Headline with ReactNode children**: Headline accepts ReactNode, allowing nested elements (emphasis, links, etc.); host is responsible for semantic correctness. See hero-014.
- **Multiple CTA/trust/status children**: Children prop accepts any ReactNode; host may compose multiple CTA, Trust, and StatusPill components in any order. See hero-015.
- **glow omitted**: Defaults to `true`; glow effect is enabled unless explicitly set to `false`. See hero-016.
- **Tagline must be phrasing content**: `tagline` renders inside a `<p>`, so passing block-level content (e.g. a `<div>`) produces invalid, browser-auto-corrected HTML. Content passed as `tagline` MUST be phrasing content (text, inline elements such as `<em>`/`<a>`) only. See hero-017.

