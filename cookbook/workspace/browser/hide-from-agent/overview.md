
This component lets the user hide parts of a page from the agent alone. It
is the agent list's entry point to the element picker, and adds nothing to
the picker but where it starts, which list it writes, and how a pick is
read in the Agent preview.

A button in the privacy toolbar, **Hide elements from agent**, opens a menu
of two items:

- **Select Items to Hide from the Agent** enters the element picker's
  selecting mode with the list set to agent. The pick dialog asks "Hide
  this from the agent?"; OK adds an agent-list entry.
- **Hidden from the Agent…** opens the element picker's popover for the
  agent list, which lists the site's agent-list entries to toggle and
  remove. It has no site switch: the agent list is always in force.

Selecting works in two of the pane's views:

- **Website**: the picker runs on the live page exactly as for the user
  list.
- **Agent preview**: the picker runs in the preview webview, in the same
  `adk-element-picker` isolated world. The preview's HTML is built by the
  agent gatekeeper and carries each node's ref as `data-adk-ref`; a pick
  there reads that ref and saves the selector the gatekeeper recorded for
  the ref when it built the page, never a selector computed against the
  preview's own markup. A pick on an element with no ref is refused.

An agent-list entry changes only what the agent receives: the gatekeeper
does not visit nodes matching enabled agent-list entries for the site, so
they are absent from every page-reading tool and from both agent views.
The user still sees the item on the page.

The preview keeps page JavaScript off. The picker world must still run
there; whether WebKit runs isolated-world scripts with content JavaScript
disabled is checked in the verification run and recorded below.

Hide from Agent is the last button in the privacy toolbar's Agents group, styled like the group's items: "Hide from Agent ▾", and "Hide from Agent: Selecting" in green while its selecting mode runs.

Right-clicking a page adds, below WebKit's items: Hide Distracting Item (live page only), Hide Item from Agents (live page and Agent preview, while the agent can see the browser), and on text Replace Private Word…, which opens the Secrets window on that word's row, made if it has none, once the window is unlocked, or brings the open window forward with it (`BrowserMenuWebView`, `WebBrowserPaneViewController+ContextMenu`).

