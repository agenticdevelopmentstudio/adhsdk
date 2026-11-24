
- **Role/trait**: The UI Card family sets no explicit ARIA `role`. It renders a plain `<div>` (`<div data-slot="card" ...>`), which carries no implicit interactive role — it is a generic, non-interactive container.
- **Label requirements**: The UI Card family's `CardTitle` renders a plain `<div data-slot="card-title">` with no heading semantics, and the source sets no `aria-labelledby`, `aria-label`, or a grouping role on the container. The family exposes neither a heading role nor an accessible name or labelled group for its title text; any heading or label association is left entirely to the caller to add.
- **Announce state changes**: Not applicable: Card has no interactive states to announce.
- **Minimum tap target**: Not applicable: Card is not an interactive element — no `onClick`/`onPress` handler exists.

