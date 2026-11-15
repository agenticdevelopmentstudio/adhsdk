
- **Data collected**: agent-list entries (selector and a label of page
  text), stored locally; nothing is sent anywhere.
- **Agent exposure**: the purpose of the component. Content matching an
  enabled agent-list entry never reaches the agent (MUST, see
  `ok-removes-from-agent`), and its presence also refuses the raw-page
  tools for the site (MUST, see `raw-tools-refused-with-entries`).
- **Preview safety**: picking in the preview never enables page scripts or
  network loads (MUST, see `preview-page-js-stays-off`,
  `preview-loads-stay-blocked`), so the preview still shows only what the
  gatekeeper put in.

