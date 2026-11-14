
- **role**: The `BatchSelectButton` MUST delegate its role to the underlying Button component ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)), which provides button semantics.
- **pressed-state-announcement**: The `BatchSelectButton` MUST announce the pressed state via `aria-pressed` attribute, updating to reflect `batch.active` on each render.
- **label-provided-by-text**: The button text (`selectLabel` or `doneLabel`) MUST serve as the accessible label.
- **keyboard-navigable**: The `BatchSelectButton` inherits keyboard support from the underlying Button component, which MUST be keyboard navigable and activatable via Enter or Space keys.

