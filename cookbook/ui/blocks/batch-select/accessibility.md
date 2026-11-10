
- **role**: The `BatchSelectButton` MUST delegate its role to the underlying Button component, which provides button semantics.
- **pressed-state-announcement**: The `BatchSelectButton` MUST announce the pressed state via `aria-pressed` attribute, updating to reflect `batch.active` on each render.
- **label-provided-by-text**: The button text (`selectLabel` or `doneLabel`) MUST serve as the accessible label.
- **keyboard-navigable**: The underlying Button component MUST be keyboard navigable and activatable via Enter or Space keys.

