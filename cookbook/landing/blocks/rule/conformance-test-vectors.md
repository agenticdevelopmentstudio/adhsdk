
| ID | Requirements | Input | Expected |
|----|----|----|----|
| rule-001 | accept-steps-array, ordered-rendering | `steps={[{term: "A", detail: "First"}, {term: "B", detail: "Second"}]}` | Component renders without error; DOM contains two `<dt>` and two `<dd>` elements in order |
| rule-002 | render-term-and-detail, accept-react-nodes | `steps={[{term: <strong>Bold</strong>, detail: <em>Italic</em>}]}` | The DOM contains `<dt><strong>Bold</strong></dt>` and `<dd><em>Italic</em></dd>` |
| rule-003 | semantic-markup, keyed-fragment-pairs | Any valid steps array | Root element is `<dl>`; direct children are `<dt>` and `<dd>` elements with no wrapper element between them and `<dl>` (the React `key` is not observable in the DOM and is not checked) |
| rule-004 | root-class | Any valid steps array | Root `<dl>` element has the class `lp-rule` |
| rule-005 | empty-steps-render-empty-list | `steps={[]}` | Component renders an empty `<dl>` element without error |
| rule-006 | accept-steps-array, render-term-and-detail | `steps={[{term: "A", detail: "1"}]}` | DOM contains exactly one `<dt>` (text "A") and one `<dd>` (text "1") |
| rule-007 | render-term-and-detail | `steps={[{term: null, detail: undefined}]}` | Component renders without error; `<dt>` and `<dd>` are present but empty (no text content) |
| rule-008 | accept-react-nodes | `steps={[{term: 42, detail: true}]}` | `<dt>` renders the text "42"; `<dd>` is present and empty (the boolean renders nothing) |
| rule-009 | accept-react-nodes | `steps={[{term: {}, detail: "x"}]}` | Informational, web-only: React itself throws ("Objects are not valid as a React child"); Rule adds no behavior here and ports need not reproduce it |

| rule-010 | missing-steps-treated-as-empty | A port is given a missing (absent or null) `steps` value | Renders an empty list, no failure (not applicable to the typed web source) |
