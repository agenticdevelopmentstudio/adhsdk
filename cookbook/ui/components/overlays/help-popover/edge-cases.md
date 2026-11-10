
- **Null or undefined entry**: Not applicable; the component does not guard against null `entry` and will error. Callers MUST provide a valid `HelpEntry` prop.
- **Empty body text**: If `entry.body` is an empty string, the component renders an empty paragraph rather than erroring. Callers are responsible for supplying meaningful body text.
- **Empty title**: If `entry.title` is an empty string or omitted, the component MUST NOT render the title section; only the body text is rendered.
- **Null or undefined flavor**: If `entry.flavor` is `undefined` or `null`, the flavor defaults to `"info"` and the Info icon is rendered.
- **Invalid flavor value**: `entry.flavor` is typed as a closed union (`"help" | "info" | "new"`) at compile time. A value outside that union bypasses the type system (e.g., from untyped JavaScript) — the component will error attempting to look up the icon and label in the `FLAVORS` table. Callers MUST ensure flavor is one of the three valid values.
- **Long title text**: Title text longer than approximately 30 characters may wrap to multiple lines; no specific line-clamp or truncation is applied by this component.
- **Long body text**: Body text is not constrained in height or line count; if `entry.body` is very long (e.g., multiple paragraphs), the popover panel will grow vertically. No maximum height or scrolling behavior is defined in this component.
- **Whitespace in entry strings**: Leading or trailing whitespace in `entry.title` or `entry.body` is preserved and rendered as-is; no trimming is performed by this component.
- **Special characters or markup in entry strings**: The component renders entry text as plain text; if `entry.body` or `entry.title` contains HTML markup or special characters (e.g., `<`, `>`), they are not interpreted. The caller is responsible for providing plain-text content.

