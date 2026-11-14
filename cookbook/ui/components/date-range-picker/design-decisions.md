
- **Decision**: Use two native date inputs rather than a calendar popover.
  **Rationale**: The source comment states the browser's own picker is keyboard- and screen-reader-complete for free, so the component adds no key handling, focus management or announcements of its own.
  **Approved**: pending

- **Decision**: Bound each end by the other (`from` by `value.to`, `to` by `value.from`) and send `min` only to the first field and `max` only to the second.
  **Rationale**: The cross bounds make the picker steer away from an inverted range; `min` and `max` then bound the whole range through the first and second field respectively, the pair the cross bounds already order.
  **Approved**: pending

- **Decision**: Do not validate, clamp or reject a typed date.
  **Rationale**: The source comment states that a typed date bypasses min and max and that a caller needing a valid range must check it; the component reports what the browser supplies and leaves validation to the caller, who knows what an invalid range means for the screen.
  **Approved**: pending

- **Decision**: Ignore a cleared field instead of reporting an empty day.
  **Rationale**: The source comment states a cleared field is ignored rather than reported as an empty day, so `onChange` never carries an empty `from` or `to` and `DateRange` stays two real days.
  **Approved**: pending

