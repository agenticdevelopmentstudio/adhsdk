
**Decision**: Represent permission state as four independent booleans, not a bitmask or enum.
**Rationale**: Four separate boolean properties make each capability explicitly named and independently readable, settable, and reasoned about, avoiding bit-shifting or mask operations. This keeps the permission model immediately readable and debuggable for a model used across many features.
**Approved**: pending

**Decision**: Default `noAccess()` to deny-all; provide `readOnly()` as a convenience default for read-only access.
**Rationale**: This follows the principle of least privilege — a newly constructed or reset permission should assume no access until explicitly granted. `readOnly()` reduces boilerplate for the common read-only pattern.
**Approved**: pending

**Decision**: `clampToParent()` combines child and parent capabilities with logical AND, and returns a new object without mutating either input.
**Rationale**: ANDing each capability preserves the permission hierarchy — a child's grant can never be more permissive than its parent allows — and returning a fresh, unmutated object keeps the function safe to call with shared or cached `Crud` instances.
**Approved**: pending

**Decision**: The interface and its functions perform no runtime validation of input shape or boolean-ness.
**Rationale**: Validation is left to the caller and to TypeScript's static type checking, keeping the model lightweight enough for use in strict TypeScript contexts where the compiler already guarantees well-formed input.
**Approved**: pending

