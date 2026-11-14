
**Decision**: Evolve the existing `AlertModal` backward-compatibly rather than introduce a new component.
**Rationale**: Defaults preserve today's behavior (`keyboard:"default"`, `destructive:false`), so call-sites that pass only `tone`/`confirmLabel`/`cancelLabel`/`onConfirm`/`onCancel` are unaffected in API while gaining the standardized header and button layout. Smoke-check every existing call-site during implementation so the visual and keyboard change is intended, not a regression.
**Approved**: pending

**Decision**: Destructive mode forces no keyboard shortcuts.
**Rationale**: A destructive action must be a deliberate, explicit click, never Enter-to-confirm.
**Approved**: pending

**Decision**: The header + footer-button system is exposed for composed dialogs.
**Rationale**: Larger dialogs stay visually uniform with alerts and confirms.
**Approved**: pending
