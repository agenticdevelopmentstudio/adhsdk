
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dev-banner-001 | message-text | `message="Custom Alert"` | Rendered text equals `"Custom Alert"` |
| dev-banner-002 | message-text | No `message` prop provided (`undefined`) | Rendered text equals `'Development Preview — Coming Soon!'` |
| dev-banner-003 | position-class | `position="fixed"` | Container has class `awt-dev-banner--fixed` |
| dev-banner-004 | position-class | `position="static"` | Container has class `awt-dev-banner--static` |
| dev-banner-005 | default-position | No `position` prop provided | Container has class `awt-dev-banner--fixed` |
| dev-banner-006 | custom-class | `className="my-custom-class"` | Container class list includes `my-custom-class` |
| dev-banner-007 | custom-class | `className=""` (empty string) | Container class list contains only `awt-dev-banner` and the position class (no empty class token) |
| dev-banner-008 | hidden-from-at | Any props | Root element has attribute `aria-hidden="true"` |
| dev-banner-009 | base-class | `position="static"`, `className="extra"` | Container class list includes `awt-dev-banner` alongside `awt-dev-banner--static` and `extra` |
| dev-banner-010 | message-text | `message={null}` (untyped JS only; the declared type rejects `null`) | Rendered text is empty; the default message is NOT used (the JS default parameter applies only to `undefined`) |
| dev-banner-011 | message-text | `message=""` | Rendered text is empty (container has no text content) |
| dev-banner-012 | message-text | `message="  padded  "` | Rendered text equals `"  padded  "` (leading/trailing whitespace preserved) |
| dev-banner-013 | non-interactive | Any props, with the default stylesheet applied | Computed `pointer-events` of the container is `none` |
| dev-banner-014 | position-class | `position` set to an out-of-range value such as `"sticky"` from untyped JS | Container has class `awt-dev-banner--sticky`; there is no fallback to `fixed`, and the default stylesheet gives it no positioning rule |## Edge Cases

- **Empty message**: `message=""` renders an empty container with no text content.
- **Null message**: `message={null}` (untyped JS only, since the declared type `string | undefined` rejects it) bypasses the JS default parameter, which applies only to `undefined`, not `null`; the banner renders with no text content, the same as an empty string.
- **Undefined or omitted message**: Falls back to the default message `'Development Preview — Coming Soon!'`, since the default parameter applies to `undefined` values.
- **Null, undefined, or empty className**: Contributes no class token to the container; the rendered class list contains only the base class and the position class.
- **Whitespace in message**: Leading and trailing whitespace in the message string is preserved and rendered as-is.
- **Out-of-range position**: A `position` value other than `'fixed'` or `'static'` (possible from untyped JS) passes through unchanged into the class `awt-dev-banner--<value>`. The component does not fall back to `'fixed'`, and the default stylesheet has no rule for that class, so the banner renders with only the base styles.
- **Long message**: The container sets `white-space: nowrap` and no maximum width or truncation, so a long or translated message overflows its box instead of wrapping or truncating (see Design Decisions: Overflow of long text).## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | `string \| undefined` | `'Development Preview — Coming Soon!'` | Text content displayed in the banner |
| `position` | `'fixed' \| 'static' \| undefined` | `'fixed'` | Controls CSS positioning behavior via class name |
| `className` | `string \| undefined` | `undefined` | Additional CSS classes applied to the root element |

