
- **Role**: The container is a plain `div` with no ARIA landmark or region role; it carries no implicit semantics of its own.
- **Content responsibility**: The `title`, `description`, and `action` are provided as ReactNode by the consumer; component does not wrap them with semantic markup.
- **Minimum height and padding**: Ensure adequate spacing around content for readability.
- **Icon visual only**: Icon is purely presentational; no aria-label is required on the component itself.

