
- **Empty message**: `message=""` renders an empty container with no text content.
- **Null message**: `message={null}` bypasses the JS default parameter, which applies only to `undefined`, not `null`; the banner renders with no text content, the same as an empty string.
- **Undefined or omitted message**: Falls back to the default message `'Development Preview — Coming Soon!'`, since the default parameter applies to `undefined` values.
- **Null, undefined, or empty className**: Contributes no class token to the container; the rendered class list contains only the base class and the position class.
- **Whitespace in message**: Leading and trailing whitespace in the message string is preserved and rendered as-is.

