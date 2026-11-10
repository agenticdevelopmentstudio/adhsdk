
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.test-pyramid](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/203de556-83a8-5211-acaf-155c49da0eb3) | partial | Best Practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.platform-compliance.deep-linking-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c2a477a7-bd42-5e3f-9ebd-5a64b4b63de4) | passed | Platform Compliance |

The passed rows rest on `DeleteEntitySection`'s `@base-ui/react/dialog`
primitive (focus trap, Escape-to-close), its `Label htmlFor` wiring, its
`apt-*`-only token usage, and the URL-driven `{basePath}/{id}/{topic}`
routing; the partial accessibility rows reflect that the All view's filter,
toggle, and its `role="radiogroup"`/`aria-label` are not yet built and no
computed contrast or hit-size values are given; `no-hardcoded-strings` is
failed because every string in `delete-entity-section.tsx` is a plain JSX
literal with no localization call; `test-pyramid` is partial because the
recipe defines integration-level vectors (a Playwright e2e suite) but no
unit-test strategy.

Process: the repo's pre-commit gate (`check_ui.py`, typecheck, lint,
`/code-review`) runs before every commit on this surface; it is a workflow
step, not a compliance check.

Separation-of-concerns is passed: `focused-topic-detail.tsx` composes only existing blocks (`PopupMenu`, `TopicDetail`, `SectionHeader`, `ResourceCard`) and leaves the focused pane's content to the consumer, and the destructive flow lives in the separate `DeleteEntitySection` block. Unit-test-coverage is partial: `deleteEntitySection.test.tsx` and the `topicDetail*.test.tsx` files in `packages/web/packages/ui/src/__tests__` cover the delete flow and the topic-detail block it composes, but no test file imports the focused-topic-detail block itself, so the popup/All-view/card-toggle composition is untested.

