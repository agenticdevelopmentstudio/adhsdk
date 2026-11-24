
- **Decision**: The control's positioning is index-based (0 to `choices.length - 1`) while the `onChange` callback exposes the selected choice's `value`, not its index.
  **Rationale**: This decouples choice order from choice identity, so callers can reorder choices without breaking `onChange` handling, at the cost of an index → value translation that is not explicit in the prop types.
  **Approved**: pending

- **Decision**: When `value` does not match any choice, the component selects the first choice (index 0) rather than throwing or rendering nothing; no dev-time warning is logged today.
  **Rationale**: This fail-safe avoids undefined rendering for an invalid `value`, at the cost of silently masking a caller error. To limit that cost, a development build SHOULD warn when `value` matches no choice (see **maintain-value-in-range**); the reference implementation does not yet. See **maintain-value-in-range** and the Configuration section's `value` entry, which record this as the single, non-contradictory contract.
  **Approved**: pending

- **Decision**: `value` is matched against `choice.value` using strict equality (`===`); no type coercion is performed between string and number values.
  **Rationale**: Preserves type safety and predictable matching, at the cost of surprising a caller who mixes numeric and string choice values across renders.
  **Approved**: pending

- **Decision**: When `disabled` is true, only the range control receives the `disabled` attribute; the label and hint continue to render as normal, non-disabled elements.
  **Rationale**: Matches standard HTML form behavior, where disabling an input does not implicitly disable its associated label. Consumers should not expect clicking the label to focus the now-disabled control.
  **Approved**: pending
