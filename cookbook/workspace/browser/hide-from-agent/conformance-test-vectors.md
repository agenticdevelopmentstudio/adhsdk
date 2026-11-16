
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hide-from-agent-001 | toolbar-button, button-menu | Show a pane's privacy toolbar; click the button | Tooltip "Hide elements from agent", id `browser.hide-from-agent`; a menu with "Select Items to Hide from the Agent" and "Hidden from the Agent…" |
| hide-from-agent-002 | select-writes-agent-list, agent-dialog-wording, website-mode-live-page | Website view on `https://example.com/`; choose Select…; pick `#secret`; OK | Dialog asked "Hide this from the agent?"; the store has an agent entry `#secret` on `example.com/*` and no user entry |
| hide-from-agent-003 | preview-pick-maps-ref, preview-mode-in-preview | Agent preview of a page whose agent page records ref `r12` with selector `main > p.note`; pick the preview element with `data-adk-ref="r12"`; OK | The saved agent entry's selector equals `page.node(ref: "r12")!.selector`, `main > p.note` |
| hide-from-agent-004 | preview-pick-maps-ref | Same preview; pick a `<b>` without a ref inside the `r12` element | The entry is saved with `r12`'s selector |
| hide-from-agent-005 | preview-pick-without-ref-refused | Pick a preview element with no ref and no ref'd ancestor; then one with ref `r999` absent from the page | Both refused with a beep; no dialog; selecting continues |
| hide-from-agent-006 | ok-removes-from-agent | After vector 003, read the preview HTML, the Agent source and `browser_snapshot` | None contains the `r12` node or its text |
| hide-from-agent-007 | user-view-unaffected | After vector 002, read the live page | No `__adk_hidden_items` rule for `#secret`; `#secret` is displayed |
| hide-from-agent-008 | list-popover, popover-select-wording | Choose "Hidden from the Agent…" with two agent entries on the site | A popover of two rows with checkboxes and −; no site switch; select button "Select items to hide from the agent" |
| hide-from-agent-009 | disabled-entry-not-applied | Uncheck the `#secret` row | The next snapshot and the refreshed preview include `#secret`'s content |
| hide-from-agent-010 | preview-page-js-stays-off, preview-loads-stay-blocked | Agent selecting in the preview of a page with an inline script and a remote image | The page script does not run; no network load is made; the picker works |
| hide-from-agent-011 | one-selecting-mode | Start user selecting from the address bar, then agent selecting from the toolbar | The user mode ends; only the agent picker is installed |
| hide-from-agent-012 | navigation-ends-selecting | Agent selecting with the dialog open; switch the view from Agent preview to Website | Dialog closed; nothing saved; idle |
| hide-from-agent-013 | raw-tools-refused-with-entries | After vector 002, call `browser_screenshot` on the page | Refused, naming the site's agent-list entries as the reason |
| hide-from-agent-014 | stop-while-selecting, every-button-has-tooltip | Start agent selecting; read the toolbar button; press Esc | Symbol `stop.circle`, tooltip "Stop selecting"; after Esc, idle with tooltip "Hide elements from agent" |
| hide-from-agent-015 | preview-dialog-preview | Agent preview; pick ref `r12`; check "Show page with selected element removed" | The `r12` node is hidden in the preview webview; the live page is unchanged |
| hide-from-agent-016 | preview-pick-saves-under-live-site | Agent preview of `https://example.com/a` with URL concealing on; pick ref `r12`; OK | The new agent-list entry's site is `example.com`, not the concealed stand-in host |
| hide-from-agent-017 | hostless-page-disabled | Open a `file:` page in a pane; read the toolbar button; then open `https://example.com/` | Disabled with tooltip "Hide elements from agent" on the `file:` page; enabled on the site |
| hide-from-agent-018 | popover-closes-with-page | Open "Hidden from the Agent…"; navigate the pane | The popover closes |

