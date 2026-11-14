
- **Null or undefined input**: The interface defines the shape but does not validate input at runtime. Callers MUST ensure they pass valid Crud objects; functions do not perform null checking or type validation.
- **All capabilities true**: When all four properties are `true`, the object represents full access. This state is valid and supported.
- **All capabilities false**: The `noAccess()` function produces this state intentionally as the most-restrictive default. It is valid.
- **Clamping identity (child equals parent)**: When the child and parent are identical, `clampToParent()` MUST return an equivalent object (all values AND'd with themselves) equal in value to the input. See crud-010.
- **Asymmetric parent restrictions**: The parent may restrict any subset of capabilities independently. For example, a parent may allow create and read but deny update and delete, and the clamping function MUST correctly AND each capability. See crud-011.

