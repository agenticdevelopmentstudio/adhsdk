
- **Role**: `<article>` element (not an ARIA landmark role) containing a button (select control) and an anchor (view paper link); button has `aria-pressed` attribute
- **Button label**: The button's entire content (badge, title, snippet, tags) acts as its label; no explicit aria-label is added
- **Link text**: "View paper" provides the link's accessible label
- **Keyboard navigation**: Button and link participate in roving tabindex when `active` is defined; Tab navigation skips inactive rows (tabIndex = -1) in list context; Standalone renders (active = undefined) use natural tab order
- **Focus indicators**: Visible focus ring (2px, 25% opacity on button, 40% opacity on link) with accent color
- **Touch target size**: Link touch target is enlarged to 24px height via invisible overlay per WCAG 2.2 SC 2.5.8 (Target Size, Minimum); button has full-width touch area inherited from flex layout
- **Mark highlights**: `<mark>` elements are semantic and not styled to remove contrast; highlight styling (gold background, 25% opacity) maintains sufficient contrast with text
- **Color as sole indicator**: Selection state is currently conveyed by border color alone (`apt-gold` vs. neutral); no additional non-color affordance (icon, background fill, thicker border) is present, which may not satisfy WCAG 1.4.1 for users who cannot distinguish the two border colors

