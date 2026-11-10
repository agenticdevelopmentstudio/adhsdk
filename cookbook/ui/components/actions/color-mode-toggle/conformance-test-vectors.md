
| ID | Requirements | Input | Expected | Notes |
|----|-------------|-------|----------|-------|
| cmt-001 | render-button | Render component with mode="light" | HTML contains `<button type="button">` element | |
| cmt-002 | render-three-icons | Render component | Three SVG icons present in DOM (Moon, Sun, RefreshCw) | CSS controls which is visible |
| cmt-003 | accept-mode-prop | mode="auto" | Component accepts and does not throw | |
| cmt-004 | accept-mode-prop | mode="dark" | Component accepts and does not throw | |
| cmt-005 | accept-mode-prop | mode="light" | Component accepts and does not throw | |
| cmt-006 | cycle-modes | mode="auto" clicked once | onChange called with "dark" | |
| cmt-007 | cycle-modes | mode="dark" clicked once | onChange called with "light" | |
| cmt-008 | cycle-modes | mode="light" clicked once | onChange called with "auto" | |
| cmt-009 | support-class-name | className="my-custom-class" passed | Element has class "my-custom-class" applied | |
| cmt-010 | read-system-dark-preference | mode="auto" and system prefers dark | Effective mode is "dark" | Via matchMedia query |
| cmt-011 | read-system-dark-preference | mode="auto" and system prefers light | Effective mode is "light" | Via matchMedia query |
| cmt-012 | listen-to-system-changes | mode="auto" and system changes from light to dark | aria-label updates to reflect new effective mode | Should reflect change without prop change |
| cmt-013 | provide-aria-label | After client mount with mode="light" | aria-label is exactly "Theme: light. Click to switch to auto." | |
| cmt-014 | provide-aria-label | After client mount with mode="auto" | aria-label is exactly "Theme: Auto (currently light). Click to switch to dark." (system prefers light) or "Theme: Auto (currently dark). Click to switch to dark." (system prefers dark) | Next mode from auto is always "dark" |
| cmt-015 | provide-title-attribute | After client mount with mode="light" | title contains "Light mode — click for auto" | Tooltip text |
| cmt-016 | provide-title-attribute | After client mount with mode="dark" | title contains "Dark mode — click for light" | Tooltip text |
| cmt-017 | provide-title-attribute | After client mount with mode="auto" | title contains "Following system (light)" or "Following system (dark)" | Based on system preference |
| cmt-018 | defer-label-until-mounted | Server-side render mode="light" | aria-label is "Theme" only | No specific mode in SSR HTML |
| cmt-019 | defer-label-until-mounted | After hydration mode="light" | aria-label becomes "Theme: light. Click to switch to auto." | Updated after mount |
| cmt-020 | handle-missing-match-media | mode="auto" in environment without matchMedia | Component does not throw; treats system as light mode | |
| cmt-021 | host-html-attribute-sync | Render with mode="light" while host sets `data-color-mode="dark"` and `.dark` on `<html>` | Moon icon visible, Sun icon hidden, badge hidden — icon selection follows the host's `<html>` attributes, not the `mode` prop | Demonstrates the coupling the requirement makes explicit |

