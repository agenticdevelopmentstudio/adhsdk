
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| publicKey | string | (required) | The list's public key from the hub's Embed panel. Must match a key on the backend. |
| apiBaseUrl | string | (required) | The base URL of the two public endpoints, with no trailing slash. May be an absolute origin (https://api.example.com) or a relative path (/api). |
| title | string | undefined (uses config.name) | Overrides the list name displayed as the form heading. |
| description | string | undefined (uses config.description) | Overrides the list description displayed below the heading. |
| buttonLabel | string | "Sign up" | Overrides the submit button text. |
| successMessage | string | "Thanks for signing up! Check your inbox for a confirmation." | Overrides the success state message. |
| collectName | boolean | true | Whether to render a name input field. |
| className | string | undefined | Custom CSS class names to apply to the root element. |

