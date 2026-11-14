
Not applicable: This control is presentational and emits no structured log events. Enabling,
dismissing, and applying a suggestion are local UI interactions; only the applied
source change is reported to the consumer (`onApply`). A harper load/lint failure
is surfaced to the user via the error state rather than logged.

