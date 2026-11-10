
- **Accessibility inheritance**: The content view controller's accessibility hierarchy is preserved; elements in the content remain discoverable with their original accessibility attributes.
- **Footer accessibility namespacing**: The `accessibilityPrefix` parameter MUST be passed to `WindowFooterBar` to ensure its controls are named under a namespace unique to this window instance (e.g., `project.footer.status`, matching the `<prefix>.status` identifier `WindowFooterBar` assigns to its status label). This prevents conflicts when multiple windows with footers exist in the application.
- **Example prefix usage**: If `accessibilityPrefix` is `"project.footer"`, the footer's status label receives the accessibility identifier `project.footer.status`, per `WindowFooterBar`'s own identifier scheme.

