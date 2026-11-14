
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support`, `keyboard-navigable`, and `semantic-markup` rest on
the source's `role="toolbar"` + `aria-label` toolbar and `DataTable`'s ↑/↓
keyboard navigation and `disabled` states; `focus-management` rests on
`AlertModal`'s own focus-trap contract, composed here for the delete confirm;
and the internationalization checks are `partial` because `emptyDetail`,
`filterPlaceholder`, and `detailsLabel` are prop-overridable while the
multi-select hint string is hard-coded with no override, and none of the four
go through a formal localization-key lookup in the source.
`separation-of-concerns` is partial: rendering is delegated to `DataTable`,
`ResizableSplit`, `ListHeader`, and `SelectionActions`, but
`list-with-details-pane.tsx` itself owns non-trivial business rules —
`writeParam`/`updateSelection`'s URL-param sync, the stale-id pruning
effects, and `defaultFilterRow`'s matching — inline in the block rather than
in an extracted hook. `unit-test-coverage` fails — no test file in the `ui`
package exercises `ListWithDetailsPane`, so none of that URL-sync, pruning,
or filtering logic is asserted.

