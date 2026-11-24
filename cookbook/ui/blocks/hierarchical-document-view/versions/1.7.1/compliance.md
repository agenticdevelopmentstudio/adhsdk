
| Check | Status | Category |
|---|---|---|
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | Artifact Formatting |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `hierarchical-document-view.tsx` and the components it composes:
frontmatter carries every required field; the breadcrumb `nav`, `dl` metadata,
real anchors in the outline, `type="button"` collapse controls, and the single
non-duplicated landmark ground `semantic-markup` as passed; `aria-expanded` /
`aria-controls` on the view-source and collapse controls, `aria-hidden` on the
chevron and scrim, the IDREF that only exists while its referent does, and the
drawer's removal from the DOM when closed ground `screen-reader-support` as
passed; native buttons, links and anchors throughout ground `keyboard-navigable`
as passed; the flat `--color-*` token family grounds `contrast-ratio` as
partial, since the source cannot show computed contrast values; the view-source
panel renders raw text while `DocArticle`'s HTML path is documented as
trusted-input only rather than type-enforced, grounding `input-sanitization` as
partial; and the single recursive tree component, the injected `LinkComponent`
(no `next/link` coupling), and the one collapse state hoisted above both the
drawer and the column ground `separation-of-concerns` as passed; and
`hierarchicalDocumentView.test.tsx`'s direct exercise of both
`HierarchicalDocumentView` and `DocPage` — slot order, the nav/rail's unwrapped
sticky column, class merging, prop forwarding, and their nesting together —
grounds `unit-test-coverage` as passed.

