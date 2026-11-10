
**Decision**: Use a native HTML `<select>` element rather than a custom listbox or dropdown.
**Rationale**: Prioritizes accessibility (native keyboard and screen-reader support), simplicity, and browser compatibility; richer interactions (multiselect, filtering, grouping) are left to a separate custom component.
**Approved**: pending

**Decision**: Accept a `className` prop for composition and use design system tokens for color and spacing rather than hardcoded values.
**Rationale**: Lets the component adapt to different design systems by swapping token/class definitions, at the cost of coupling the component to the presence of those definitions.
**Approved**: pending

**Decision**: Generate an ID via `useId()` when none is provided, while still accepting an `id` prop for caller control.
**Rationale**: Ensures the label can always be associated to the select, preventing lost accessible names, while letting a caller match a server-rendered ID when needed.
**Approved**: pending

**Decision**: Implement Select as a controlled component; `value` is a required prop and the parent owns the state.
**Rationale**: Keeps the parent always aware of the current value, enabling undo, validation, or other state-management patterns without the component maintaining parallel state.
**Approved**: pending

