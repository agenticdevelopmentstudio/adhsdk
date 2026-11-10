
- **Empty or null rendering**: Not applicable. SendIcon is a functional component that always renders; it has no inputs to be null or empty.
- **Container scaling**: When the parent container is sized differently than 20×20, the icon does not resize — it stays fixed at 20×20 because `width` and `height` are hardcoded on the `<svg>` element (see **maintain-aspect-ratio**). A caller needing a different size overrides those attributes directly, or wraps the icon and applies a CSS transform.

