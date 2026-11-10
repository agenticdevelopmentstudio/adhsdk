
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`graceful-degradation` passes because a malformed field, an unmapped icon, an unknown container, or a duplicate view id each costs only that one field or entry — per `unreadable-key-note-per-key`, `icon-codicon-unmapped`, `unknown-container-note`, and `duplicate-view-id-first-wins` — never the extension's other views or the whole build. `idempotent-operations` passes because building views is a pure function (`build-is-pure`) over immutable inputs and a fixed table, so calling it twice with identical arguments MUST return bit-for-bit identical containers, views, and notes lists, with no accumulation between calls. `no-hardcoded-strings` fails because every note's `detail` sentence is an unlocalized English string literal (see Localization), with no localization key of any kind. `unit-test-coverage` passes: `ContributedViewsBuilderTests.swift` exercises registry-id namespacing, the tree/webview default, every icon-resolution branch (mapped, unmapped, animated, blank, file-path), the `when`-clause note, all four axis-rule target kinds, both duplicate-view-id shapes (within one target and across two), container-without-icon survival, both directions of the unreadable-key leniency, and declared-order preservation for both containers and views.

`separation-of-concerns` passes because `ContributedViews.swift` imports only Foundation and splits its work across separate types: the value records (`ContributedViewContainer`, `ContributedView`, `ContributedViewNote`), the codicon lookup table (`CodiconSymbols`), and the pure `ContributedViewsBuilder`; the builder only classifies the manifest and never renders, persists, or evaluates `when` clauses.

