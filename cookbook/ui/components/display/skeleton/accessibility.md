
- **Role**: Presentational; the component assigns no ARIA role itself (see **aria-hidden-while-loading**).
- **Label requirements**: None from the component itself. A consumer applying **aria-hidden-while-loading** SHOULD also set `aria-busy="true"` on the parent that shows the placeholder, so assistive technology reads the container's busy state rather than the skeleton's empty markup.
- **Announce state changes**: Delegated to the parent's `aria-busy` state; the skeleton itself announces nothing.
- **Keyboard interaction**: Not applicable. This is a non-interactive element.

The component renders a plain `div` with no `aria-hidden`, `aria-busy`, or role attribute of its own; per **aria-hidden-while-loading**, suppressing the placeholder or announcing loading status is left entirely to the consumer (see Design Decisions).

