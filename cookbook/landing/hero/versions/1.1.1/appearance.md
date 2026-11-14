
- **Corner radius**: Inherited from Screen component; no additional radius applied
- **Padding**: Inherited from Screen component and `lp-hero` CSS class
- **Font**: Headline uses `<h1>` default sizing overridden by `.lp-hero h1` (`clamp(1.85rem, 5.2vw, 3.3rem)`, weight 200); tagline uses `<p>` default with `lp-tag` class styling (`1.05rem`)
- **Background**: Inherited from Screen component (centred screen exception, per `css/blocks.css` comment)
- **Foreground/Text**: Headline color is inherited from the page body's ink token (`color: var(--lp-ink, #ededed)`, set in `css/base.css`), with emphasized (`<b>`) text brightened via `.lp-hero h1 b` (`var(--lp-accent-bright, #d8d8d8)`); tagline color is set by `.lp-hero p.lp-tag` (`var(--lp-ink-dim, #a0a0a0)`), with `em` text brightened back to `var(--lp-ink, #ededed)` via `.lp-hero p.lp-tag em`
- **Border**: None
- **Shadow**: Glow effect applied via Screen component when `glow={true}` (default)
- **Min/Max size**: No explicit constraints; inherits Screen sizing

