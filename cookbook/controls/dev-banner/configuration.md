
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | `string \| undefined` | `'Development Preview — Coming Soon!'` | Text content displayed in the banner; `null` is accepted only from untyped JS and renders empty (it does not use the default) |
| `position` | `'fixed' \| 'static' \| undefined` | `'fixed'` | Controls CSS positioning behavior via class name; any other value (untyped JS only) passes through into the class name with no fallback |
| `className` | `string \| undefined` | `undefined` | Additional CSS classes applied to the root element |

