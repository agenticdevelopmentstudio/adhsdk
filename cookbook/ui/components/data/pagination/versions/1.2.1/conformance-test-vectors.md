
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | hides-when-single-page | render `<Pagination page={1} totalPages={1} onPageChange={fn} />` | renders nothing (empty container) |
| T2 | renders-pagination-landmark, shows-page-caption | `page={1} totalPages={3}` | a `nav[aria-label="Pagination"]` containing the caption `"Page 1 of 3"` |
| T3 | disables-prev-on-first | `page={1} totalPages={3}` | `Prev` button is disabled |
| T4 | pages-forward | `page={1} totalPages={3}`, click `Next` | `onPageChange` called with `2` |
| T5 | disables-next-on-last, shows-page-caption | `page={3} totalPages={3}` | caption `"Page 3 of 3"`; `Next` button disabled |
| T6 | pages-backward | `page={3} totalPages={3}`, click `Prev` | `onPageChange` called with `2` |
| T7 | controlled-page | rerender from `page={1}` to `page={2}` (`totalPages={3}`) | caption updates to `"Page 2 of 3"`; neither button disabled |
| T8 | forwards-classname | `className="mt-4"` | `nav` element carries the `mt-4` class |
| T9 | hides-when-single-page | `page={1} totalPages={0}` | renders nothing (empty container) |
| T10 | shows-page-caption, disables-next-on-last | `page={5} totalPages={3}` | caption `"Page 5 of 3"`; `Next` button disabled |
| T11 | disables-prev-on-first | `page={1} totalPages={3}` | `Next` button is enabled |
| T12 | disables-next-on-last | `page={3} totalPages={3}` | `Prev` button is enabled |

