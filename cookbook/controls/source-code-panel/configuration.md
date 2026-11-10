
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| code | string | required | Source code to display |
| lang | string | 'tsx' | Language identifier for Shiki syntax highlighting |
| theme | string | undefined | Explicit Shiki theme name; if set, overrides CSS-derived theme |
| showCopy | boolean | true | Show copy-to-clipboard button in header |
| filename | string | undefined | Filename to display in header; if not provided, language code is shown |
| className | string | undefined | Additional CSS class to append to root element |
| maxHeight | string or number | undefined | Max height for code body container; applied as inline style. A numeric value is interpreted as pixels (React appends `px` to unitless numeric style values). |

