
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | search-region-wrapper | Render with only `search` | A single `role="search"` element wraps the controls |
| T2 | search-field-control, search-field-label | `search.label="Search documents"`; type `agents` | `getByRole("searchbox", { name: "Search documents" })` resolves; `onChange("agents")` fires |
| T3 | filter-row-omitted-when-empty | Render with no `filters` | No `combobox`/select is present |
| T4 | one-select-per-filter, filter-options-list | Two filters (`category` opts `[Agents, Retrieval]`, `tag` opts `[rag]`) | Two labelled selects; `category` lists `All categories`, `Agents`, `Retrieval` (in order); `tag` lists `All tags`, `rag` |
| T5 | filter-value-sync | `category.value="Agents"`; select `Retrieval` | Select shows `Agents` initially; `category.onChange("Retrieval")` fires |
| T6 | filter-value-sync | `category.value="Agents"`; choose `All categories` | `category.onChange("")` fires |
| T7 | filter-options-list | One axis, `options: [{ value: "st-1", label: "Todo" }, { value: "st-2", label: "Done" }]`; select `Done` | Options read `Todo`/`Done` and none reads `st-1`; `onChange("st-2")` fires |
| T8 | filter-options-list | One axis, `options: ["Backlog", { value: "it-1", label: "Sprint 3" }]` | Option `Backlog` has value `Backlog`; option `Sprint 3` has value `it-1` |
| T9 | filter-row-children, filter-row-omitted-when-empty | One filter plus a `<button>Platforms</button>` child; then the same child with no filters; then `{false}` as the only child | Button and select share one row; the child alone still draws the row; `{false}` draws no row (one child element under the root) |
| T10 | orientation-layout | Render default, then rerender `orientation="inline"` | Root has `flex-col` by default; inline drops it for `flex-wrap`, and the field wrapper carries `flex-1 min-w-48` |
| T11 | autofill-form-scope | Render default, then rerender `asForm` | Root is a `DIV`, then a `FORM`; exactly one `role="search"` either way; `fireEvent.submit` on the form reports the event cancelled |
| T12 | filter-value-sync | `category.value` set to a value absent from `category.options` (e.g. after the option universe changed) | The select's displayed option is the all-pass entry (index 0) even though `category.value` is still the stale, unmatched string; no `onChange` fires until the user picks something |

