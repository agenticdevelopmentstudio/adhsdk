
Visual styling is determined entirely by CSS classes applied to the element. The component applies:

- **Default class**: `aws-explanation`, defined by the `.aws-explanation` rule in the user-settings stylesheet (`packages/web/packages/controls/src/user-settings/styles.css`) and shared with the sibling Panel, Group, Field, Header, Divider, Stack, and Hint components through the `:where(...)` selector at the top of that file.
- **Custom classes**: Additional classes from the `className` prop are applied alongside the default

Appearance properties, from `.aws-explanation` in `styles.css`: margin `0`, color `var(--aws-text-muted)` (resolves through `--color-text-secondary` / `--text-muted` to `#8a8a9a`), font size `0.8rem`, line-height `1.5`. Font family is not set on `.aws-explanation` itself — it inherits `var(--aws-font-sans)` (`system-ui, sans-serif`) from the ancestor `.aws-panel`.

