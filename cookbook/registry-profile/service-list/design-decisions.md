
**Decision**: Styling is delegated entirely to CSS classes (`rp-services`, `rp-services__heading`, `rp-services__list`, `rp-service`, `rp-service__title`, `rp-service__description`, `rp-service__price`) rather than inline styles.
**Rationale**: Keeps presentation separate from markup and lets styling be managed independently of the component.
**Approved**: pending

**Decision**: The React key for each list item is `service.title`; the component requires titles to be unique within a given `services` array rather than accepting a separate identifier prop (see **unique-titles**).
**Rationale**: The source has no `id` field on `PublicService` to key on instead; adding one would be new behavior beyond what the source implements today.
**Approved**: pending

**Decision**: Pricing formatting (`priceText`) stays inline in `ServiceList.tsx` rather than being extracted into a shared formatter ingredient.
**Rationale**: It currently has exactly one consumer; extracting it now would create a shared component with no second caller to validate the abstraction against. Revisit once another recipe needs the same formatting rules.
**Approved**: pending

**Decision**: The component renders nothing (`return null`) when `services.length === 0`, rather than rendering an empty section.
**Rationale**: Lets parent layouts collapse the section entirely instead of showing an empty heading with no content.
**Approved**: pending

**Decision**: The section and item heading levels are fixed at `<h2>` and `<h3>` rather than accepting a configurable heading level.
**Rationale**: The source hardcodes both levels; hosts embedding this component MUST place it at a point in the page outline where `<h2>` is the correct next heading level.
**Approved**: pending

