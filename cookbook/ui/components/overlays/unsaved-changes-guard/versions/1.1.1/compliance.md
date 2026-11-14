
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Keyboard navigation and focus trapping for the confirmation dialog are delegated to `UnsavedChangesAlert`, which this source does not show, so those two checks are partial; `safe-defaults` passes because every guarded exit in this source — `beforeunload`, anchor clicks, popstate — blocks by default and only proceeds after an explicit user confirmation or an explicit `approveNavigation()` call. `separation-of-concerns` is partial because the registry itself lives apart in `lib/navigation-guard.ts`, but the click-interception, popstate, and sentinel state-machine logic sits inline in `UnsavedChangesGuard` rather than in an extracted hook; `unit-test-coverage` passes on `unsavedChangesGuard.test.tsx`'s exhaustive exercise of link interception, the registry, history/unload, sentinel tracking, and multi-guard arbitration.

