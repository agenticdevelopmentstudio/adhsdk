
- **Empty message**: `message=""` renders an empty container with no text content.
- **Null message**: `message={null}` (untyped JS only, since the declared type `string | undefined` rejects it) bypasses the JS default parameter, which applies only to `undefined`, not `null`; the banner renders with no text content, the same as an empty string.
- **Undefined or omitted message**: Falls back to the default message `'Development Preview — Coming Soon!'`, since the default parameter applies to `undefined` values.
- **Null, undefined, or empty className**: Contributes no class token to the container; the rendered class list contains only the base class and the position class.
- **Whitespace in message**: Leading and trailing whitespace in the message string is preserved and rendered as-is.
- **Out-of-range position**: A `position` value other than `'fixed'` or `'static'` (possible from untyped JS) passes through unchanged into the class `awt-dev-banner--<value>`. The component does not fall back to `'fixed'`, and the default stylesheet has no rule for that class, so the banner renders with only the base styles (see dev-banner-014).
- **Long message**: The container sets `white-space: nowrap` with no maximum width or truncation, so a long or translated message overflows its box instead of wrapping or truncating (see Design Decisions: Overflow of long text).
