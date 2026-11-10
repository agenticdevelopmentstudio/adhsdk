
- **Role**: Non-semantic `<div>` — a `<div>` carries no implicit ARIA role. `Screen`'s `as="div"` is deliberate (see **render-as-div** and the root-is-non-semantic Design Decision): the host MUST wrap Hero in an appropriate semantic landmark (e.g. `<section>`, `<main>`) if the page needs one
- **Label requirements**: Headline (`<h1>`) serves as the primary heading; tagline (`<p>`) provides context
- **Announce state changes**: Not applicable; Hero is a static presentation component with no interactive state changes
- **Minimum tap target**: Not applicable; Hero contains no interactive controls directly. Child components (CTA buttons, etc., each with their own recipe) MUST meet the web target-size minimum of 24×24 CSS px (WCAG 2.5.8 Target Size (Minimum), Level AA) and SHOULD meet 44×44 CSS px (WCAG 2.5.5 Target Size (Enhanced), Level AAA) where feasible
- **Keyboard navigation**: Not applicable; Hero is non-interactive. Child components MUST be keyboard navigable

