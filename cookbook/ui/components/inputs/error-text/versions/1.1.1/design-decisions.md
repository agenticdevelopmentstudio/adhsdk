
**canonical-home**

**Decision**: Error Text is the single, authoritative component for all inline error and validation messages across the platform. Styling (color and text size), the alert role, and the conditional render logic live in exactly one place.
**Rationale**: Consolidating ownership prevents drift across surfaces. If a surface needs a different visual treatment for errors, that need signals a review of whether Error Text should be extended, or whether the surface genuinely requires a different component, rather than a silent fork of the styling.
**Approved**: pending

**two-variants-one-treatment**

**Decision**: `ErrorText` and `DialogErrorText` share the same color and text-size treatment; the only difference between them is the rendered element (`<p>` vs. `<span class="block">`).
**Rationale**: HTML forbids nesting `<p>` inside `<p>`, so the element choice is a structural constraint, not a design choice — treatment stays uniform while structure adapts to context.
**Approved**: pending

**classname-layout-flexibility**

**Decision**: The `className` prop lets callers add padding/margin and, per **default-text-size**, adjust text size in dense layouts (e.g., `text-xs` in the DM composer and notification inbox) without requiring a new component variant.
**Rationale**: `cn()` merges caller classes with the defaults, so metric overrides are possible while the core treatment defined in **apply-error-color** is preserved by convention.
**Approved**: pending

**color-and-role-non-negotiable**

**Decision**: The error color and the `role="alert"` attribute are the two parts of the treatment that callers must never change; text size may be overridden, color and role may not.
**Rationale**: `role="alert"` is a fixed JSX attribute, outside `className`, so it cannot be overridden through this component's public API at all. The color token, by contrast, passes through `cn()`'s `tailwind-merge` step and could technically be overridden by a conflicting color class — this is prevented by convention and code review, not by a runtime guard, so a caller needing a different color (e.g., yellow for warning, blue for info) is signaling that the message is not an error and should use a different component.
**Approved**: pending

**null-return-over-empty-element**

**Decision**: When no error is present, the component returns `null` rather than rendering an empty, invisible alert element.
**Rationale**: Reduces DOM noise and prevents screen reader users from encountering empty alerts.
**Approved**: pending

**span-variant-for-dialogs**

**Decision**: `DialogErrorText` renders a `<span>` with block display instead of a second `<p>`-based treatment.
**Rationale**: Dialog descriptions render as `<p>` tags (per Base UI convention), and HTML forbids nesting `<p>` inside `<p>` — the browser would auto-close the outer paragraph. A block-displayed `<span>` preserves the same line-by-line layout while respecting that structural rule; the top-margin token (see **dialog-error-text-top-margin**) separates it from the description text.
**Approved**: pending

**alert-role-for-screen-reader-announcement**

**Decision**: Both variants set `role="alert"` so screen readers are notified when the error text appears.
**Rationale**: In dialogs particularly, the error text changes dynamically under a focus trap with no other visual affordance calling attention to it, making the alert role the most reliable notification available — though see the **render-when-error-present** edge case on hidden containers for the one sequence where that reliability doesn't hold.
**Approved**: pending

