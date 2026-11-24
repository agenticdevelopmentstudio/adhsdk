
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `message_bubble.detail_button.label` | "Show details" | Aria label for the optional detail-indicator button (Web); currently hardcoded in `MessageBubble.tsx` rather than sourced from a resource file — see **no-hardcoded-strings** in Compliance |
| `message_bubble.failure.reason` | — (caller-provided) | Failure reason text comes from `deliveryStatus.failed(reason)`; the component renders it verbatim and does not localize it — the caller is responsible for localizing the reason before passing it in |

