
- **No actions provided**: When `actions` is an empty array, no action buttons are rendered (only the Delete button if `onDelete` is provided).
- **No delete callback**: When `onDelete` is undefined, the Delete button does not render at all. The component functions with only custom actions.
- **Empty selected IDs**: When `selectedIds` is an empty array, all selection-required actions are disabled and the Delete button is disabled, but standalone actions remain enabled.
- **Multiple simultaneous selections**: The component receives an array of IDs and passes all of them to action handlers. No limit is enforced on the array length.
- **Rapid action clicks**: Each action handler is called independently when its button is clicked. No debouncing or click prevention is implemented; it is the action handler's responsibility to manage race conditions or duplicate invocations.
- **Duplicate action IDs**: The component uses each action's `id` as its React list key. Action `id`s MUST be unique; a duplicate does not stop either button from rendering or from invoking its own `onClick`, but callers must not rely on stable list identity across renders when ids collide. See **duplicate-action-ids**.
- **Custom action variant**: An action can override the default `ghost` variant by specifying a `variant` property matching Button's variant prop.

