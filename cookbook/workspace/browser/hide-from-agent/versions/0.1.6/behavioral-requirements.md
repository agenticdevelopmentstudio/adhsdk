
- **toolbar-button**: The privacy toolbar MUST show a button with the
  symbol `person.crop.circle.badge.xmark`, the tooltip "Hide elements from
  agent" and the accessibility identifier `browser.hide-from-agent`.
- **button-menu**: Clicking the button MUST show a menu with exactly two
  items, "Select Items to Hide from the Agent" and "Hidden from the
  Agent…", in that order.
- **select-writes-agent-list**: "Select Items to Hide from the Agent" MUST
  start the element picker's selecting mode with the list set to agent, so
  every entry it saves is an agent-list entry and none is a user-list
  entry.
- **agent-dialog-wording**: The pick dialog started from this button MUST
  ask "Hide this from the agent?"; its scopes, preview checkbox and buttons
  MUST be the element picker's.
- **list-popover**: "Hidden from the Agent…" MUST open the element picker's
  popover for the agent list, anchored to the button, listing the site's
  agent-list entries with their enabled checkboxes and the − remove
  button, and with no site switch checkbox.
- **popover-toggle**: A click on the toolbar button while its "Hidden from
  the Agent…" popover is open MUST close the popover and show neither the
  menu nor the popover again; the element picker's address-bar button
  behaves the same for its own popover.
- **popover-select-wording**: The agent popover's select button MUST read
  "Select items to hide from the agent" and start the same selecting mode
  as the menu item.
- **one-selecting-mode**: A pane MUST run at most one selecting mode across
  both lists; starting agent selecting while user selecting runs (or the
  reverse) MUST end the running one first.
- **stop-while-selecting**: While agent selecting runs, the toolbar button
  MUST act as its stop control (tooltip "Stop selecting"), and Esc MUST end
  it, as for the user list.
- **website-mode-live-page**: In the Website view, the picker MUST run on
  the live page and save the selector the picker computes there.
- **preview-mode-in-preview**: In the Agent preview view, the picker MUST
  run in the preview webview's `adk-element-picker` world, not on the live
  page.
- **preview-pick-maps-ref**: A pick in the Agent preview MUST read the
  clicked element's `data-adk-ref` (or that of its nearest ancestor that has
  one) and save the selector recorded for that ref in the agent page the
  preview is showing, with that node's label.
- **preview-pick-saves-under-live-site**: A pick in the Agent preview MUST
  save its entry under the live page's site, never under the address the
  agent page carries, which is concealed and may be a stand-in host.
- **preview-pick-without-ref-refused**: A pick in the Agent preview on an
  element with no ref, or whose ref has no node in the shown agent page,
  MUST be refused with a beep; no dialog opens and selecting continues.
- **preview-page-js-stays-off**: Selecting in the Agent preview MUST NOT
  turn on page JavaScript in the preview; only the picker world may run.
- **preview-loads-stay-blocked**: Selecting in the Agent preview MUST NOT
  lift the preview's block on network loads.
- **preview-dialog-preview**: In the Agent preview, the dialog's "Show page
  with selected element removed" MUST hide the chosen node in the preview
  webview, not on the live page.
- **ok-removes-from-agent**: After OK, the gatekeeper's next build of the
  page MUST omit the nodes the new entry matches, and an open Agent
  preview or Agent source view MUST refresh and no longer show them.
- **user-view-unaffected**: An agent-list entry MUST NOT hide anything from
  the user: the live page MUST carry no `__adk_hidden_items` rule for it.
- **disabled-entry-not-applied**: An agent-list entry the user unchecks in
  the popover MUST stop being applied by the gatekeeper at its next build,
  and the agent views MUST refresh to show the node again.
- **raw-tools-refused-with-entries**: While the site has enabled agent-list
  entries, the raw-page tools (`browser_screenshot`, `browser_click_at`,
  `browser_evaluate`) MUST be refused for that site's pages, as the
  gatekeeper's rules require; this component's entries are what trigger
  that.
- **navigation-ends-selecting**: A committed navigation, a switch between
  Website and Agent preview, a tab switch, or closing the tab or pane MUST
  end agent selecting and close the dialog without saving.
- **hostless-page-disabled**: On a page with no host (`file:`, `about:`,
  `data:`, or no address) the toolbar button MUST be disabled, keeping its
  tooltip, except as the stop control while agent selecting runs, and
  starting agent selecting there MUST beep and start nothing, since an
  entry there could only be saved for every site.
- **popover-closes-with-page**: The "Hidden from the Agent…" popover MUST
  close on a committed navigation, a front-page change, a tab switch and
  pane discard, as the element picker's popover does.
- **every-button-has-tooltip**: The toolbar button MUST carry a tooltip.

