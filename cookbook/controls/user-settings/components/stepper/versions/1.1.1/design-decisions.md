
- **Decision**: All numeric values are clamped to `[min, max]` bounds immediately after any change (button click or each keystroke of direct input).
  **Rationale**: This prevents out-of-range values from being passed to the consumer and avoids state inconsistency.
  **Approved**: pending

- **Decision**: When `min` or `max` is not provided, they default to `-Infinity` and `+Infinity` respectively.
  **Rationale**: This allows unconstrained ranges while simplifying the API (no separate "unbounded" mode).
  **Approved**: pending

- **Decision**: Buttons are disabled when an operation would exceed bounds (`value <= min` disables decrement; `value >= max` disables increment).
  **Rationale**: This prevents repeated clicks from attempting invalid operations and provides clear affordance to users.
  **Approved**: pending

- **Decision**: Non-numeric input is silently ignored via a `Number.isNaN()` check; an empty or whitespace input parses to `0` and is committed like any other value (see Edge Cases).
  **Rationale**: This provides lenient error handling without introducing error states, though it means blank input is treated as zero rather than as "no value."
  **Approved**: pending

- **Decision**: Buttons use `aria-label` for concise, standalone labels ("Decrement", "Increment") rather than `aria-describedby`.
  **Rationale**: The action is self-contained and descriptive, so a short accessible name is sufficient.
  **Approved**: pending

- **Decision**: The stepper emits only `onChange`; it performs no analytics tracking and no logging.
  **Rationale**: A leaf form primitive should not own telemetry — mixing instrumentation into input handling couples unrelated concerns. Consumers that need analytics or logging compose it around **call-onchange-handler**.
  **Approved**: pending

