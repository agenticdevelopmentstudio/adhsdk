
- **Decision**: Evolve the existing `AlertModal` backward-compatibly rather than introduce a new component. **Rationale**: Defaults preserve today's behavior (`keyboard:"default"`, `destructive:false`); existing call-sites that pass only `tone`/`confirmLabel`/`cancelLabel`/`onConfirm`/`onCancel` are unaffected in API while gaining the standardized header + button layout. Smoke-check each known call-site during implementation — `LoginCard`, `ProviderLinkHandler`, `SsoCallback`, and admin `authentication/page.tsx` — so the visual/keyboard change is intended, not a regression.
- **Decision**: Destructive mode forces no keyboard shortcuts. **Rationale**: A destructive action must be a deliberate, explicit click — never Enter-to-confirm.
- **Decision**: The header + footer-button system is exposed for composed dialogs. **Rationale**: Larger dialogs (e.g. the invitation modal) stay visually uniform with alerts/confirms.

