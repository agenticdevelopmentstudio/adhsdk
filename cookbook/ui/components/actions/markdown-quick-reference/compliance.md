
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The trigger carries `aria-label="Markdown quick reference"` and the reference
content is a semantic `<dl>`, both driven by the shared `Popover` primitive's
`aria-expanded`/`aria-controls` wiring and keyboard (click or Escape)
handling — the source shows nothing that would make any of these `partial` or
`failed`. `no-hardcoded-strings` is `failed` because the title, aria-label,
default trigger text, and all nine row labels are fixed English strings with
no override or localization path from this component. `separation-of-concerns`
passes because `MarkdownQuickReference` only supplies the markdown-specific
`MARKDOWN_SYNTAX` entries and props to the shared `SyntaxQuickReference` shell,
with no popover, dismissal, or rendering logic of its own. `unit-test-coverage`
passes because `markdownQuickReference.test.tsx` exercises the collapsed
default, opening/listing the syntax entries, Escape dismissal, and a custom
trigger label.

