
`coverAllControl.test.tsx` renders the control by itself and has one test per vector. The host stacks also exercise it: `hierarchicalTopicDetail.test.tsx` ("`<<<` / `>>>` collapse and expand every list", including the hierarchical menu variant, and "is not in the narrow layout") and `detailTitle.test.tsx`, which finds the control by `[data-htd-cover-all]`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ca-001 | collapse-callback, collapse-button (test: `<<<` / `>>>` collapse and expand every list) | `canCollapse=true`; click "Collapse all lists" | `onCollapseAll` called once; in the host every list becomes covered |
| ca-002 | expand-callback, expand-button (test: `<<<` / `>>>` collapse and expand every list) | `canExpand=true`; click "Expand all lists" | `onExpandAll` called once; in the host every list opens |
| ca-003 | collapse-enabled-flag, expand-enabled-flag, flags-independent | `canCollapse=false`, `canExpand=true` | Collapse button disabled; expand button enabled |
| ca-004 | collapse-enabled-flag, expand-enabled-flag, flags-independent | `canCollapse=true`, `canExpand=false` | Collapse button enabled; expand button disabled |
| ca-005 | disabled-inert | `canCollapse=false`; click the collapse button | `onCollapseAll` is not called |
| ca-006 | always-present | Both flags false | Both buttons still rendered, both disabled |
| ca-007 | group-semantics, hook-attribute (test: detailTitle.test.tsx finds `[data-htd-cover-all]`) | Default render | A group named "Collapse or expand all lists" carrying `data-htd-cover-all` |
| ca-008 | tooltip-matches-label, button-name | Default render | Collapse button title and name are both "Collapse all lists"; expand "Expand all lists" |
| ca-009 | glyph-decorative | Default render | The chevron wrapper and divider are `aria-hidden` |
| ca-010 | button-type | Default render inside a form | Clicking either button does not submit the form |
| ca-011 | group-container | Default render | Collapse button precedes the divider, the divider precedes the expand button |
| ca-012 | stateless | Rerender with new flags | The enabled states follow the new flags immediately; nothing persists between renders |

