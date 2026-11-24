
**Decision**: The `gap` prop accepts either a number or a string.
**Rationale**: Numeric values are converted to pixels; string values allow any CSS unit (rem, em, %, etc.). This accommodates both fixed-pixel spacing and responsive relative sizing.
**Approved**: pending

**Decision**: The `style` prop is spread last in the merged styles object, giving it precedence over layout-derived styles.
**Rationale**: This allows consumers to override gap, alignment, or justification when needed without modifying the component.
**Approved**: pending

**Decision**: The className array is filtered to remove falsy values (empty strings) before joining.
**Rationale**: This prevents malformed class strings and ensures clean DOM output.
**Approved**: pending

**Decision**: When `gap` is undefined, the CSS `gap` property is not set.
**Rationale**: This allows default styling from the CSS class definitions to apply, reducing redundant inline style declarations.
**Approved**: pending

**Decision**: On platforms where the native layout primitive maps `gap` and `justify` onto the same property (Compose `Arrangement`, `NSStackView`/`UIStackView` `distribution`), `gap` takes precedence; `justify` is approximated with the closest available distribution, or dropped.
**Rationale**: The React/Web source applies `gap` and `justifyContent` as independent CSS properties with no conflict between them; a priority is needed only where a platform's API cannot represent both independently.
**Approved**: pending

**Decision**: The base class name `aws-stack` is a fixed string literal in the source, not a template variable or configurable prop.
**Rationale**: `Stack.tsx` hardcodes the prefix and exposes no mechanism for consumers to override it; the `aws` prefix predates this recipe and its origin is not documented in the source.
**Approved**: pending

