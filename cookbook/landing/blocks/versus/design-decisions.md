
**Decision**: Both panels render through a single shared implementation rather than duplicated markup per side.
**Rationale**: Reduces the risk of divergent rendering between "us" and "them" — a fix applied to the shared implementation automatically applies to both sides, and both panels are guaranteed identical structure for the same props (see **consistent-side-structure**).
**Approved**: pending

**Decision**: `lede` is checked only for presence (`!== undefined`), not emptiness; `points` is checked for both presence and non-zero length. An explicitly empty `lede` (e.g. an empty string) still renders a styled empty paragraph; an explicitly empty `points` array renders nothing.
**Rationale**: The component can't distinguish an intentionally empty value from a caller mistake, so it renders whatever is defined. Callers who want no lede or no points must omit the prop entirely rather than pass an empty value (see **render-optional-lede**, **render-optional-points**).
**Approved**: pending

