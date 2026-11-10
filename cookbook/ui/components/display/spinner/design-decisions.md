
- **Decision**: The component renders an indeterminate spinner (no progress percentage), not a determinate progress bar.
  **Rationale**: The source code and comment explicitly state "Indeterminate loading spinner." A determinate progress bar serves a different use case (showing completion percentage) and is not in scope.
  **Approved**: pending

- **Decision**: The component renders the Lucide icon directly, with no wrapping `<div>` or other container.
  **Rationale**: This keeps the DOM minimal and lets the caller control layout and spacing via the parent container's styling.
  **Approved**: pending

- **Decision**: Default classes are merged with the caller's `className` via `cn()` (`clsx` + `tailwind-merge`).
  **Rationale**: `tailwind-merge` resolves Tailwind class precedence correctly, so the caller's classes override the defaults. This lets callers customize size and color without needing to know the default class names.
  **Approved**: pending

- **Decision**: The component forwards all remaining props to the underlying `Loader2` component via `{...props}` instead of whitelisting individual props.
  **Rationale**: This lets callers add event handlers (if `Loader2` supports them), data attributes, or other HTML attributes without the Spinner component needing to explicitly whitelist each one — the same extensibility the `className` customization provides.
  **Approved**: pending

- **Decision**: The `aria-label` is hardcoded to `"Loading"` rather than exposed as a prop.
  **Rationale**: The source code does not expose the label as a prop. Callers who need a different or localized label would need to render the `Loader2` icon directly with a custom label instead of using this component.
  **Approved**: pending

