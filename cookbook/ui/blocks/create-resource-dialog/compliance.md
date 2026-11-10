
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the source: interactive elements carry meaningful labels and the correct `role`/`aria-modal`/`aria-label` (screen-reader-support, semantic-markup); every action is reachable through native buttons and a global Escape handler (keyboard-navigable); no code moves, traps, or restores focus (focus-management, documented above under Focus management); and the close button's `icon-sm` size measures 28×28px against the 44×44/48×48 guideline unless a host raises `--adh-button-min-height`/`--adh-button-min-width` (touch-target-size). All five user-visible strings ("Cancel", "Save", "Saving…", "Close", "Failed to create.") are hardcoded literals in the component rather than resource lookups (string-externalization, no-hardcoded-strings). separation-of-concerns passes because the dialog owns only dirty-tracking, save orchestration, and the close guard, delegating all field presentation to the host's `renderForm` and the confirm/discard UI to `UnsavedChangesAlert`. unit-test-coverage is partial: `createResourceDialogExit.test.tsx` covers only the close-guard paths (Cancel/Discard/Stay); no test in the repo exercises the save flow (`display-create-error`, `invoke-onsaveerror-on-create-failure`, `support-optional-save-gate`, and related requirements).

