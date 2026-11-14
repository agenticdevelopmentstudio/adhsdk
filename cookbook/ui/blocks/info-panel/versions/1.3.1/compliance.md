
| Check | Status | Category |
|---|---|---|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`platform-theming` is `passed`: the source styles exclusively with `apt-*`
theme tokens (no raw hex, no `!important`), which theme correctly in light and
dark. `semantic-markup` is `partial`: the `<section>` gets a computed
`aria-label` and the leading icon is `aria-hidden`, but the source leaves the
region unnamed for a non-string `title` with no `ariaLabel` (see
**label-region**). `keyboard-navigable` is `partial`: the scroll body is a
real `overflow-y-auto` container, but the source adds no `tabIndex` to it, so
keyboard reachability depends on focusable content the host renders inside.
`separation-of-concerns` is `passed`: the component is pure presentation over
its header/body slot props, with only the trivial `aria-label` precedence
computed inline. `unit-test-coverage` is `partial`: `infoPanel.test.tsx`
exercises only the host-attribute passthrough and the `aria-label` precedence
chain, with no test covering the icon, count, center, actions, or scroll-mode
rendering.

