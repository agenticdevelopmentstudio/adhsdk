
The `sites` array supplies site names and emoji, so caller-localized site names are shown as given. The container's accessible name `aria-label="Agentic family"` is a hardcoded English, app-specific string in `OrbRow.tsx` (see **set-navigation-role**); the component has no prop or localization lookup to replace it, so localizing it means changing the component.
