1. **Decision**: The title "Discard unsaved changes?" and the button labels "Discard" and "Stay" are fixed; `description` is the single customizable prop.
   **Rationale**: Fixed wording is a consistency guarantee across all surfaces using this component, so every editable surface asks the same question in the same words. "What our prompt says" is shared knowledge, while "what is at risk on this surface" is the surface's own: overriding `description` lets a surface be specific (e.g., "Staged users will not be saved" vs. "Composed invitation cannot be sent"), and a surface with nothing more specific to say passes nothing and receives the default.
   **Approved**: pending

2. **Decision**: The component never saves or persists data itself.
   **Rationale**: Keeps it decoupled from any specific persistence mechanism (localStorage, server API, IndexedDB, etc.) and reusable across surfaces with different storage strategies; persisting changes remains the surface's responsibility, not the alert's.
   **Approved**: pending

3. **Decision**: Setting `destructive` on the underlying AlertModal disables its keyboard shortcuts entirely and sets initial focus to "Stay", so neither Enter nor Escape can invoke Discard.
   **Rationale**: Losing edits must be a deliberate click or tap, not a keyboard accident (#requirements/discard-requires-explicit-action).
   **Approved**: pending

4. **Decision**: The alert is a modal dialog that traps focus and blocks interaction outside itself, including pointer dismissal via the backdrop.
   **Rationale**: The user cannot make further changes while the prompt is open — the choice is binary and immediate, and only clicking a button ("Discard", "Stay", or ✕) resolves it (#requirements/dismissal-outcomes).
   **Approved**: pending

