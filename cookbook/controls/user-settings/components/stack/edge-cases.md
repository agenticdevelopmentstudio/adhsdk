
- **Undefined or null children**: The root `div` renders with the layout classes and no child nodes. See #requirements/render-children, stack-011 and stack-018.
- **Empty children array**: Same outcome as undefined children. See #requirements/render-children and stack-012.
- **Gap as zero**: Numeric and string zero are applied as written. See #requirements/apply-gap-prop, stack-013 and stack-014.
- **Conflicting inline styles**: `style` wins over the `gap`/`align`/`justify` props because it is spread last. See #requirements/apply-inline-styles and stack-015.
- **Empty or absent className**: No empty or extra whitespace tokens appear in the class attribute. See #requirements/apply-class-names and stack-016.
