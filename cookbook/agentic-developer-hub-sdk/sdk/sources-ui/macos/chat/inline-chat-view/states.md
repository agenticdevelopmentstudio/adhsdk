
| State | Appearance change |
|-------|------------------|
| Default (idle, not engaged) | Transcript at `sizing.inactive` height if configured (defaults to `sizing.active` height when `inactive` is omitted); input visible, no focus ring. |
| Engaged (focused, interacting) | Input field has focus ring (platform-dependent); if `inactive` sizing set, transcript expands to active height with 0.2s animation (or instant if `transition: 'none'`). |
| Thinking (remote typing/status) | Thinking indicator animates (dots or custom glyph rotation). |
| Streaming (reply incoming) | If `statusWhileStreaming`, thinking indicator continues animating while transcript updates. |
| Minimal (collapsed, inactive) | Transcript height exactly 0 and hidden; input row remains visible and enabled. |
| Input disabled | Input field renders but does not accept input or send; visual state per platform disabled appearance. |
| Backdrop shown/hidden | Backdrop view visible or hidden; if animated, animation runs or stops. |

