
1. **Decision**: Use native `<input type="radio">` elements rather than styled divs with custom click handlers.
**Rationale**: Native inputs work correctly with all assistive technologies and require no JavaScript event handling to achieve keyboard interaction.
**Approved**: pending

2. **Decision**: Wrap the radiogroup in a `<fieldset>` and render the label in a `<legend>`.
**Rationale**: This follows HTML standards for form grouping and is the correct semantic structure for grouped form inputs; screen readers announce the legend as the group's accessible name.
**Approved**: pending

3. **Decision**: Support both a per-choice hint and a field-level hint.
**Rationale**: This allows flexible UX patterns where a group needs both overall field instructions and choice-specific guidance.
**Approved**: pending

4. **Decision**: Generate a unique group name via `useId` when no `name` prop is provided.
**Rationale**: Prevents multiple RadioGroup instances on the same page from interfering with each other's selection state, which would happen if all used the same hardcoded name.
**Approved**: pending

5. **Decision**: Make the component generic over `T` (`string | number`).
**Rationale**: Supports both string and numeric choice values, allowing consumers to work with their own type systems without additional conversion.
**Approved**: pending

