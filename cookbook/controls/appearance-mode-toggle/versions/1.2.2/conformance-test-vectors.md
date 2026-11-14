
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toggle-001 | render-button | Component renders | Button element with `type="button"` exists in DOM |
| toggle-002 | read-appearance-mode | `document.documentElement.dataset.appearanceMode = 'dark'` | Component reads mode as 'dark' |
| toggle-003 | read-appearance-mode | `document.documentElement.dataset.appearanceMode = 'invalid'` | Component treats invalid mode as 'auto' |
| toggle-004 | read-resolved-appearance | `document.documentElement.classList.contains('dark') = true` | Component resolves appearance as 'dark' |
| toggle-005 | read-resolved-appearance | `document.documentElement.classList.contains('dark') = false` | Component resolves appearance as 'light' |
| toggle-006 | display-icon-based-on-resolved | Resolved appearance is 'dark' | Moon icon SVG is rendered and sun icon is not |
| toggle-007 | display-icon-based-on-resolved | Resolved appearance is 'light' | Sun icon SVG is rendered and moon icon is not |
| toggle-008 | display-badge-in-auto-mode | Mode is 'auto' | Badge span with nested SVG is rendered |
| toggle-009 | display-badge-in-auto-mode | Mode is 'light' or 'dark' | Badge is not rendered |
| toggle-010 | dispatch-cycle-event-on-click | User clicks button | Custom event 'awt:appearance-cycle' is dispatched on window object |
| toggle-011 | listen-for-appearance-changed-event | 'awt:appearance-changed' event fires on window | Component's internal state updates and component re-renders |
| toggle-012 | set-aria-label, set-title-attribute | Mode is 'auto', resolved is 'light' | aria-label and title both equal "Appearance: Auto (currently light). Click to switch to dark." |
| toggle-013 | set-aria-label, set-title-attribute | Mode is 'dark' | aria-label and title both equal "Dark mode — click for light" |
| toggle-014 | set-aria-label, set-title-attribute | Mode is 'light' | aria-label and title both equal "Light mode — click for auto" |
| toggle-015 | accept-classname-prop | `className="custom"` prop | Button element has class names including both 'awt-appearance-mode-toggle' and 'custom' |
| toggle-016 | render-hydration-safe | SSR/hydration scenario before event listener attached | No access to `document` or `window` during server render; initial output is auto/light |
| toggle-017 | render-hydration-safe | Server render with no `document` (auto/light); client's hydrating render runs against a live `document.documentElement` already carrying `data-appearance-mode="auto"` and class `dark` | The hydrating render reads mode 'auto'/resolved 'dark' immediately (not deferred until after mount), differing from the server's auto/light markup — moon icon and "(currently dark)" label, not the sun icon/"(currently light)" the server emitted |

