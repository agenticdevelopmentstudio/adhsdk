
**Decision**: The standard allowlist's node kinds are document, landmark,
heading, paragraph, text, list, list item, link, button, text field, text
area, checkbox, radio, select, option, table, row group, row, cell,
column header, row header, image, label, and the ARIA grid kinds grid,
tree grid and grid cell.
Attributes: `aria-label` and `title` on every kind; `href` on links; `alt`
on images; `placeholder`, `name` and `type` on text fields and text areas;
`name` on selects, checkboxes and radios; `level` on headings.
**Rationale**: The spec's list (text, headings, paragraphs, lists, links,
buttons, form controls with labels and values, tables, images as alt text,
landmarks) made concrete; the spec allows tighter.
**Approved**: pending

**Decision**: To reproduce today's tree format line for line, a landmark
carries its landmark role (main, navigation, banner, contentinfo,
complementary, search, form, region, article) and nodes carry the legacy
states (checked, disabled, expanded, selected, pressed, required) as
allowlisted values from fixed vocabularies; a value outside the vocabulary
is dropped. The walker sends them as the attributes `role` (on a landmark)
and `states` (space-separated, on any node); the allowlist's JSON carries
both vocabularies as `landmarkRoles` and `states`.
**Rationale**: `snapshot-tool-contract-unchanged` needs the roles and
states the legacy renderer prints; fixed vocabularies keep them from
carrying page text. This is beyond the spec's attribute list and needs the
owner's check.
**Approved**: pending

**Decision**: The string path returns `""` for unavailable and conflicting
privacy, where `BrowserAgentPrivacy.concealing` returns `"(concealed)"`.
**Rationale**: The plan's contract; an empty string carries nothing, and
those states already close the pane to tools.
**Approved**: pending

**Decision**: HTML mapping: landmark → `section` (or `nav`/`main`/`header`/
`footer` by role), heading → `h1`–`h6` by level, paragraph → `p`, list →
`ul`, list item → `li`, link → `a` with the sanitized `href`, button →
`button`, text field → `input` (disabled; a `contenteditable` or
`role=textbox` field holding content → `<div class="adk-textfield"
role="textbox" aria-disabled="true">` holding that content, the text the
agent reads), text area → `textarea`
(disabled, holding its value), checkbox/radio → `input` of that type (disabled), select →
`select` (disabled), option → `option`, table/row/cell → `table`/`tr`/`td`,
label → `label`, image → `<span class="adk-image">[image: alt]</span>`,
text → escaped character data. One fixed stylesheet of the builder's own
in the head is allowed; no `style` attribute.
**Rationale**: Every element is one the builder chooses; controls are
disabled so the preview cannot submit anything.
**Approved**: pending

**Decision**: The old full-page walk in `BrowserSnapshot.js` is removed or
reduced to what non-agent callers still need; the snapshot tool no longer
uses it.
**Rationale**: Two walkers would be two routes from page to agent.
**Approved**: pending

**Decision**: Text rendering uses the main landmark when there is one,
else the whole page, so the text tool's description ("its main region,
else the whole body") stays true.
**Rationale**: `snapshot-tool-contract-unchanged`.
**Approved**: pending

**Decision**: An element the legacy snapshot counted as interactive that
nothing else classifies keeps its reference: one that is editable (its own
`contenteditable` or inherited) is a text field, and one with an `onclick`
or a `tabindex` of 0 or more is a button. Such a button is named from its
content unless it holds links or controls, which then stay its children.
**Rationale**: `snapshot-tool-contract-unchanged`: the snapshot tool
promises "refs for every interactive element", and custom controls are
common; with privacy on there is no coordinate-click fallback.
**Approved**: pending

**Decision**: Roles with no allowlist kind (dialog, alert, status, menu,
menubar, toolbar, tablist, tabpanel, tree, progressbar, meter, group,
figure, separator, tooltip, radiogroup, and the like) are flattened into
their parent: their children are walked and the role itself is not
emitted. Such an element that is interactive by the rule above keeps a
reference as a button. Table row groups and headers are not flattened:
`thead`, `tbody` and `tfoot` (written or implied by the parser) and an
explicit `rowgroup` are a row group, printed and numbered as `rowgroup`;
`th` and an explicit `columnheader` print as `columnheader`, and an
explicit `rowheader` as `rowheader`, exactly as `browser_snapshot` prints
them today.
**Rationale**: The allowlist is fixed ("tighter is fine"), and
over-stripping is the accepted failure; table rowgroup, columnheader and
rowheader are kept exactly as `browser_snapshot` prints them today, because the spec
says the tool contract is unchanged, line for line
(`snapshot-tool-contract-unchanged`).
**Approved**: pending

**Decision**: Roles are renamed to the allowlist kind they fold into:
the table family is not renamed — `grid`, `treegrid` and `gridcell` have
kinds of their own and print as written, and `rowgroup`, `columnheader`
(and `th`) and `rowheader` print as today (in the HTML a grid or tree grid
is a `table` and a grid cell a `td`); `listbox` as combobox (a select); `tab`, `menuitem`
and `treeitem` as button; `switch` and `menuitemcheckbox` as checkbox and
`menuitemradio` as radio; `searchbox`, `spinbutton` and `slider` as text
fields typed search, number and range. The folded `switch`,
`menuitemcheckbox` and `menuitemradio` keep the legacy name from content.
**Rationale**: Forced by the allowlist's kinds. The tree's format (syntax,
references, states, levels) is unchanged, and folding to clickable kinds
keeps the references. The grid roles and table rowgroup, columnheader and
rowheader are kept exactly as
`browser_snapshot` prints them today, because the spec says the tool
contract is unchanged, line for line (`snapshot-tool-contract-unchanged`).
**Approved**: pending

**Decision**: Frames (`iframe`, `frame`) and embedded documents (`object`,
`embed`) are not walked, and the frame node itself is not emitted.
**Rationale**: The agent-list selectors were picked against the top
document, so what a frame holds is content the user never reviewed for the
agent and the list cannot be trusted to cover; uncertain content is
stripped. (A same-origin frame's document could be queried; it is not, by
choice.)
**Approved**: pending

