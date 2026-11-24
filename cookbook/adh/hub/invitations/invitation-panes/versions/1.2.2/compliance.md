
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy & Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on this file's own sections: Accessibility documents that
`passes-required-aria-label` is this file's one direct, forced contribution
while every other interactive/semantic element is delegated (partial); Privacy
and Logging show the file collects, stores, transmits, and logs nothing of its
own (passed); Localization shows every user-facing string is hardcoded with no
i18n key or lookup (failed); Overview shows data-fetching, persistence, and the
notes/history UI are all pushed to the caller, leaving this file pure
presentation (passed); and Edge Cases/Design Decisions show the `onSend`
rejection reason is discarded via `() => undefined` with no log or rethrow
(failed, see `reports-send-rejection-reason`).

`unit-test-coverage` is `partial`: no test file for `invitation-panes.tsx` exists under the `adh-ui` test targets (`packages/web/packages/adh-ui/src/__tests__/` holds tests for other blocks only); the only coverage is indirect, through `packages/web/packages/features/ecosystems/src/EcosystemInvitationPanes.test.tsx`, which renders the three panes via their ecosystem wrappers and pins the header placement above the scrollable grid, so the `onSend` rejection handling and the `aria-label` values are untested.

