
The shared `RemovableChip` in `@adh-sdk/ui` — a `Badge` with a trailing ✕ remove
affordance. It is the one home for the "removable chip" treatment (recipient chips,
tag/category chips): rather than each caller re-inventing a badge-plus-✕, they render
this element.

The chip body is the shared `Badge` (so it inherits the badge tone `variant`s and the
mono/uppercase pill styling); the ✕ is a **real `<button>`** carrying `removeLabel`
as its accessible name, so a chip reads to assistive technology as
"`<value>`, Remove `<value>`". Clicking the ✕ invokes the consumer-supplied
`onRemove` callback — the component is stateless, so the consumer owns the list and
decides what removal does (typically filtering the value out of its state).

A single export ships from `@adh-sdk/ui/components/removable-chip`: the
`RemovableChip` component.

