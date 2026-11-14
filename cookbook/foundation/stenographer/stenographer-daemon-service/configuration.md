
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_URL` | environment variable | unset | Overrides the daemon base URL when it parses as a URL. |
| stenographer HTTP base URL | URL constant | `http://127.0.0.1:22847` | The loopback address used when the variable is unset or invalid. |
| `healthPollInterval` | seconds | 30 | How often the implementation polls `/health` for restarts. |
| `session` | `URLSession` | `.shared` | The injected transport of the HTTP implementation. |
| request timeouts | seconds | 10, 15, 605 | Quick reads, heavy reads, and summarize. |

