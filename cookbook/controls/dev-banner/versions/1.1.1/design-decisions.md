
**Decision**: Hide the banner from assistive technology via `aria-hidden="true"`, treating the development-preview message as a decorative, visual-only notice rather than information all users must receive.
**Rationale**: The container also sets `pointer-events: none` and is styled as a rotated ribbon/badge — evidence it is meant as passive visual chrome, not an interactive or critical alert. If the development status is later judged semantically important to all users, `aria-hidden` should be removed and an appropriate role (e.g. `role="status"`) added instead.
**Approved**: pending

