
**Decision**: The standard allowlist's node kinds are document, landmark,
heading, paragraph, text, list, list item, link, button, text field, text
area, checkbox, radio, select, option, table, row, cell, image and label.
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
`button`, text field → `input` (disabled), text area → `textarea`
(disabled), checkbox/radio → `input` of that type (disabled), select →
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

