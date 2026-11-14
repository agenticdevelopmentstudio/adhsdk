
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` and `keyboard-navigable` pass because the toggle and every
apply action are real `<button>` elements with an accessible name (`aria-label`,
including the per-suggestion `Replace "<flagged>" with "<suggestion>"` form) and
`aria-pressed` state. `focus-management` passes because the panel is the shared
`Popover`, which supplies Escape/outside-click dismissal and focus restore to the
toggle. `semantic-markup` passes because the problem list is a labelled `<ul>` of
`<li>` rows with a real `aria-hidden` error icon. `contrast-ratio` and
`touch-target-size` are partial because the source uses only `apt-*` tokens and the
shared `Button`'s size variants, but the actual contrast values and pixel
dimensions are defined outside this file. `no-hardcoded-strings` fails because
"Checking…", "No issues found.", and the "Spell check is unavailable…" copy are
literal English strings with no i18n layer; `string-externalization` is partial
because the toggle's own label is externalized via the `label` prop but those
other strings are not. Security, Privacy and Data, and User Safety are omitted:
the component makes no network calls (harper runs offline), stores/collects no
data of its own, and produces no logs (see Logging above). `separation-of-concerns`
passes because the component isolates harper behind the `MarkdownLinter`/
`CreateMarkdownLinter` DI seam, so the UI never references harper directly and
a fake linter can stand in for tests. `unit-test-coverage` passes because
`markdownSpellcheck.test.tsx` covers the off-by-default toggle, lazy linter
creation, linting and listing problems, the empty state, and applying a
suggestion.

