
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source directly: the keyboard sensor, `aria-live` Announcements, and dnd-kit's `role`/`tabIndex`/`aria-label` attributes back the passed and partial accessibility checks (partial on keyboard-navigable because DragItem's `keyboard` prop defaults to false and needs a host-provided alternative path); the grip's `h-6 w-4` dimensions and its reliance on dnd-kit's own CSS transitions with no `prefers-reduced-motion` handling back the two failed checks, and the `apt-gold/25` focus ring's self-admitted possible AA shortfall backs the partial contrast-ratio check; and the hardcoded English announcement sentences (`Picked up …`, `… is over …`, etc.) alongside the fully overridable item/zone/target names back the partial internationalization check. `separation-of-concerns` passes because sorting/dragging logic (`landsAfter`, `asHandleProps`, `useDragSensors`) is extracted into standalone helpers and hooks, leaving the exported components as thin, mostly stateless wrappers; `unit-test-coverage` passes because `dnd.test.tsx` imports `DragGrip`, `DragItem`, `DragSurface`, `DropTarget`, `SortableItem`, `SortableSurface`, and `SortableZone` directly and exercises them with meaningful assertions.

