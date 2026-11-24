
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the source: the textarea's accessible name comes from
`htmlFor`/`id` (T1–T2) and the upload button pairs a visible "Upload .md"
label with the visually-hidden native `<input type="file">`
(screen-reader-support passed); every control — textarea, upload button,
quick-reference trigger — is a native or Base UI element reachable by Tab
(keyboard-navigable passed); the composition uses only `apt-*` tokens with no
raw hex (contrast-ratio passed); `EditorToolbar`'s `role="toolbar"`/`aria-label`
and the `Label`↔`Textarea` `htmlFor` association are wired correctly
(semantic-markup passed); `label`, `toolbarLabel`, and `placeholder` are all
overridable via props, but the upload control's `Upload .md` button text has
no override (no-hardcoded-strings partial); the upload control filters by
`accept` client-side but the source performs no server-side, size, or
encoding validation of the chosen file's content before calling `onUpload`
(input-sanitization partial); and the editor holds and forwards exactly the
`value`/file content the consumer wires in, nothing more (data-minimization
passed). Touch-target sizing and toolbar keyboard-roving are governed by the
composed Button and EditorToolbar recipes, not re-assessed here; User Safety
is omitted because the editor neither moderates nor publicly displays content.
`separation-of-concerns` passes: `markdown-editor.tsx` composes `Label`,
`Textarea`, `EditorToolbar`, and `MarkdownQuickReference`, and its only
non-presentational code — `UploadMarkdownControl`'s file read — is isolated
in its own small subcomponent rather than entangled with the editor's
layout. `unit-test-coverage` fails — no test file in the `ui` package
exercises `MarkdownEditor` or `UploadMarkdownControl`.

