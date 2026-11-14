
- **Role**: presentational image; MUST be treated as an icon, not interactive
- **Label requirement**: The component itself MUST NOT have a label or `aria-label`. A containing button or action that uses SendIcon as its visual indicator MUST provide an accessible label for the entire control (e.g., `aria-label="Send message"`).
- **Semantic use**: SendIcon SHOULD be wrapped in a `<button>` or similar interactive control; the label belongs to the wrapper, not the icon itself.

