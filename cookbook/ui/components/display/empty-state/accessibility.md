
- **Role**: The container is a plain `div` with no ARIA landmark or region role; it carries no implicit semantics of its own.
- **Content responsibility**: The `title`, `description`, and `action` are provided as ReactNode by the consumer; component does not wrap them with semantic markup.
- **Icon visual only**: The icon wrapper carries no `aria-hidden` or label. Hiding a decorative icon from screen readers (for example `aria-hidden="true"` on the SVG) is the consumer's job.

