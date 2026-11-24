
The shared `Badge` in `@adh-sdk/ui`: a status chip, "a 1:1 match of the deployed header badge (`.adh-header__badge`)" per the source comment. It is a transparent, pill-shaped `span` with a 1px border, set in uppercase mono type, where the border and the text share one tone color. Six tones are offered through a `variant` prop: `neutral`, `accent`, `orange`, `blue`, `success` and `error`. The source comment says the first four mirror the header: neutral, accent, orange for Development Preview and blue for Coming Soon.

The source exports two names: the `Badge` component and `badgeVariants`, the class-variance-authority function that builds its class string, so other elements can borrow the look. `Badge` is a stateless presentational element. It accepts every prop a `span` accepts and spreads them onto the element after its own attributes.

