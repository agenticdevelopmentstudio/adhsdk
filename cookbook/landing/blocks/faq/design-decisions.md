
- **Decision**: Build the disclosure list from native HTML `<details>`/`<summary>` elements rather than a custom JavaScript accordion component.
  **Rationale**: Eliminates the need for stateful JavaScript logic, reduces bundle size, ensures the component works without client-side rendering, and leverages the browser's built-in accessibility and print handling. Trade-off: the animation and visual styling are browser-default and less customizable than a fully scripted accordion; customization is achieved through CSS.
  **Approved**: pending

- **Decision**: Key each rendered entry by its array index (`key={i}`) rather than by a caller-supplied identifier (index-based-keying).
  **Rationale**: Acceptable for a static or rarely-reordered list. If the `entries` array is mutated (items added, removed, or reordered), React reuses DOM nodes by index, which can cause open/closed state to attach to the wrong entry. The source does not validate or guard against this, and defines no `id` field — keeping the array stable is the caller's responsibility.
  **Approved**: pending

- **Decision**: Make `open` optional per entry, defaulting to `false`, with the convention (documented in a source comment) that normally exactly one entry carries it.
  **Rationale**: Showing exactly one answer expanded by default reads as an FAQ section rather than a list of collapsed links. The component does not enforce this convention — the caller controls which entries are open.
  **Approved**: pending

- **Decision**: Define no custom `onClick`, `onChange`, or other event handlers; delegate all interactivity to the browser's native `<details>` implementation.
  **Rationale**: Keeps the component functional without JavaScript and preserves browser behaviors like print preservation and Find searchability (**print-preserves-open**, **findable-text**). Callers who need to react to state changes (e.g., an analytics event) must add a wrapper outside this component.
  **Approved**: pending

- **Decision**: Describe this component as a "disclosure list," not an "accordion," in its title, summary, and tags.
  **Rationale**: Several entries can be open at the same time, which is not how an accordion usually behaves. [adhsdk.ingredient.ui.components.layout.accordion](cookbook:85ce8c4b-5233-48af-9268-30cddd4747f9) is the single-open variant; readers who expect single-open behavior are pointed there instead of finding it here under a name that overpromises.
  **Approved**: pending

