
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| category-field-001 | render-combobox | Render with default props. | Combobox input is visible and accepts text input. |
| category-field-002 | render-browser-button | Render with default props. | "Choose…" button is visible and clickable. |
| category-field-003 | update-value-on-combobox-change | Type "test" in the combobox and confirm a selection matching an item in `options`. | `onChange` is called once with "test". |
| category-field-004 | update-value-on-browser-select | Click "Choose…", select an option in the entity chooser, confirm the selection. | `onChange` is called once with the selected option's name. |
| category-field-005 | accept-value-not-in-options | Render with `value="custom-name"` where "custom-name" is not in `options` list. | Component displays "custom-name" in combobox without error; breadcrumbs show it if `nodes` includes it. |
| category-field-006 | display-breadcrumbs-when-nodes-provided | Render with `value="leaf"`, `nodes` containing a tree with "leaf" at the end of a trail. | One breadcrumb trail is displayed with ancestors leading to "leaf". |
| category-field-007 | show-all-filing-paths | Render with `value="shared"` where "shared" node has two parents in `nodes`. | Two breadcrumb trails are displayed, each showing a different path to "shared". |
| category-field-008 | path-count-aria-label | Render with one trail; then render with two trails. | `aria-label="<label> path"` (singular) for one trail; `aria-label="<label> paths"` (plural) for two or more trails. |
| category-field-009 | chevron-separators | Render breadcrumb trail with three nodes. | Two ChevronRight icons (12px) are visible between the three breadcrumbs; none appears before the first. |
| category-field-010 | leaf-breadcrumb-accent | Render breadcrumb trail with ancestor and leaf. | Leaf breadcrumb renders in the leaf-accent color token (`text-apt-gold`). |
| category-field-011 | ancestor-breadcrumb-muted | Render breadcrumb trail with three nodes. | First two (ancestor) breadcrumbs render in the muted color token (`text-apt-text-muted`); the third (leaf) renders in the leaf-accent token. |
| category-field-012 | breadcrumb-truncation | Render breadcrumb with very long node name in narrow container. | Text is truncated with ellipsis; no overflow occurs. |
| category-field-013 | rename-button-when-onrename-provided | Render with `onRename` callback and `disabled={false}`. | Each breadcrumb is a `<button>` element. |
| category-field-014 | static-breadcrumb-without-onrename | Render without `onRename` callback. | Breadcrumbs are `<span>` elements, not buttons. |
| category-field-015 | static-breadcrumb-when-disabled | Render with `onRename` callback but `disabled={true}`. | Breadcrumbs are `<span>` elements, not buttons. |
| category-field-016 | rename-button-label | Render breadcrumb button with `noun="category"` and `node.name="taxonomy"`. | Button's `aria-label` is "Rename category taxonomy". |
| category-field-017 | open-rename-dialog-on-crumb-click | Render with `onRename` callback; click a breadcrumb button. | CategoryRenameDialog opens with `open={true}`. |
| category-field-018 | rename-dialog-receives-node | Click a breadcrumb to open rename dialog. | Dialog receives the clicked node via `node` prop, the `nodes` tree, and `options` via `extraNames`; no `value` prop is passed. |
| category-field-019 | close-rename-dialog-on-confirm-or-cancel | Rename dialog is open; user confirms or cancels. | Dialog closes (`renaming` state becomes `null`). |
| category-field-020 | rename-follows-selected | Selected node is renamed from "old" to "new"; confirm rename. | `onChange("new")` is called. |
| category-field-021 | rename-ignores-unselected | Rename a node that is not the currently selected node; confirm. | `onChange` is NOT called; component's value remains unchanged. |
| category-field-022 | disabled-state | Render with `disabled={true}`. | Both combobox and chooser have `disabled={true}` attribute; breadcrumbs are static text, rename buttons are inactive. |
| category-field-023 | layout-prop | Render with `layout="inline"`. | The Field wrapper receives `layout="inline"` and renders its label beside the control instead of above it. |
| category-field-024 | classname-prop | Render with `className="custom-class"`. | The Field wrapper's root element includes `custom-class` in its class list. |
| category-field-025 | hint-prop | Render with `hint="Select a category from the list"`. | The Field wrapper renders "Select a category from the list" below the label. |
| category-field-026 | hide-breadcrumbs-without-trail | Render with `value=""` and `nodes` provided. | Breadcrumb `<nav>` section is not rendered. |
| category-field-027 | hide-breadcrumbs-without-trail | Render with `value="something"` but no `nodes` prop. | Breadcrumb `<nav>` section is not rendered. |
| category-field-028 | combobox-placeholder | Render with `noun="topic"`. | Combobox placeholder is "Type a topic…". |
| category-field-029 | browser-trigger-label | Render with default props. | Entity chooser trigger button label is "Choose…". |
| category-field-030 | browser-input-label | Render with `noun="skill"`. | Entity chooser input label is "Filter or add a skill"; placeholder is "Filter or add a skill…". |
| category-field-031 | browser-aria-label-from-label | Render with `label="Skills"`. | Entity chooser `ariaLabel` is "Browse skills". |
| category-field-032 | hide-breadcrumbs-without-trail | Render with `value="missing"` where no node in `nodes` has that name. | `nodeForName` resolves to `null`; breadcrumb `<nav>` section is not rendered; combobox and chooser remain interactive. |
| category-field-033 | rename-follows-selected | Click a breadcrumb to open the rename dialog; submit a name for which `onRename` rejects. | `onChange` is NOT called and `value`/breadcrumbs are unchanged; the dialog's own error handling is CategoryRenameDialog's — see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3). |
| category-field-034 | disabled-state | Open the rename dialog via a breadcrumb click, then re-render CategoryField with `disabled={true}`. | The dialog remains open; the source does not close it or otherwise alter it on this transition — CategoryField's `renaming` state is independent of `disabled`. |
| category-field-035 | show-all-filing-paths | Render with `value="shared"` where "shared" has 5 parents in `nodes` (5 distinct filing paths). | Only 4 breadcrumb trails are displayed (`MAX_TRAILS`); the 5th filing path is not rendered. |

