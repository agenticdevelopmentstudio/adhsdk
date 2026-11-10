
- **Role**: The root is a generic container (`<div>`); the `<h3>` title establishes semantic structure for screen readers.
- **Heading level**: Title always renders as `<h3>` (see **render-title**); the component exposes no way to change this. Consumers MUST place the card where an `<h3>` fits in the page's heading hierarchy (for example, within a section introduced by `<h2>`), rather than expecting the card to adapt to a different level.
- **Label requirements**: Title text MUST be meaningful and describe the card's subject. If `title` is an icon or symbol, it MUST be accompanied by accessible text (either in the prop or wrapping element).
- **Kicker labeling**: Kicker text SHOULD provide context (e.g., "Preview", "Latest", "23 specialists"). Screen readers will encounter it before the title due to DOM order. If kicker is interactive content (a link), the consumer MUST ensure the kicker and title together form a descriptive label.
- **Content accessibility**: Content (`children`) MUST be accessible HTML; this component imposes no restrictions but does not enhance accessibility for complex children — responsibility remains with the consumer.
- **Minimum tap target**: Not applicable: component is not interactive; if children contain interactive elements, those MUST meet 44×44pt (iOS) / 48×48dp (Android) / 44×44px (web) minimum tap targets per platform guidelines.

