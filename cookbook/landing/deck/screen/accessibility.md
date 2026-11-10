
- **Semantic role**: When rendered as `<section>` (`as: 'section'`), the element only becomes a `region` landmark once it has an accessible name; without one, assistive technology exposes it as a generic section, not a landmark. When rendered as `<div>` (`as: 'div'`), there is no implicit role. Role depends solely on the `as` prop — CSS classes and stylesheets have no effect on ARIA semantics.
- **Label requirement**: Screen accepts no `aria-label`, `aria-labelledby`, or other pass-through attribute on its root element beyond `id`, `align`, `as`, `className`, and `glow`. Consequently, a `<section>` rendered by Screen has no accessible name through Screen's own props — hosts that need a labelled landmark region MUST provide that name outside Screen's public API.
- **Content accessibility**: Screen does not define accessibility for its children; child components are responsible for their own accessible implementation.

