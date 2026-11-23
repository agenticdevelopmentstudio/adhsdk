
- **user-list-enabled-selectors**: The renderer MUST hide exactly the
  selectors the hidden-items store returns as the user list's enabled
  selectors for the page's address, and MUST NOT render agent-list entries
  (the agent list hides content from the agent, not from the user).
- **single-style-element**: The renderer MUST put its rules in one style
  element with the identifier `__adk_hidden_items`, and MUST replace that
  element's rules, never add a second element, each time it is applied.
- **display-none-rule-per-selector**: The style MUST hold one rule per
  selector, of the form `<selector> { display: none !important; }`.
- **installed-at-document-start**: The style MUST be installed as a user
  script that runs at document start, so matching items are hidden from
  the first paint of a new page load.
- **reapplied-on-change**: When the hidden-items store announces a change,
  the renderer MUST recompute the selectors for each pane's current address
  and apply them to the live page without a reload, so enabling, disabling,
  adding or removing an entry, or flipping the site switch, takes effect
  immediately.
- **reapplied-on-navigation**: On every committed navigation, the renderer
  MUST recompute the selectors for the new address and apply them, so a
  page on another site never keeps the previous site's rules.
- **late-content-hidden**: Content the page adds after the style is
  applied MUST be hidden by the same rules without re-applying them; no
  DOM mutation observer is used.
- **bad-selector-isolated**: A selector the page's style engine rejects
  MUST be skipped on its own; every other selector's rule MUST still take
  effect.
- **selectors-as-json**: Selectors MUST be passed to the page's script as a
  JSON-encoded array and MUST NOT be interpolated into script source, so no
  selector text can end a string or run as script.
- **empty-removes-style**: Applying an empty selector list MUST remove the
  `__adk_hidden_items` element, so the page draws as it is.
- **preview-rule-set**: The engine MUST offer a temporary preview rule set
  that hides a given list of selectors in a separate style element with the
  identifier `__adk_hidden_items_preview`; setting it to none MUST remove
  that element.
- **preview-independent**: The preview rule set MUST NOT change the
  hidden-items store or the `__adk_hidden_items` element, and setting or
  clearing it MUST leave the saved list's rules as they were.
- **single-owner-of-user-scripts**: The style user script MUST be added in
  the engine's single user-script owner together with every other user
  script, so rebuilding the user-script list for any reason keeps the
  hidden-items style in it.
- **user-hidden-hidden-from-agent**: Items hidden by this style MUST also be
  absent from what the agent receives, by way of the gatekeeper skipping
  `display: none` content; this renderer MUST NOT add any exception that
  keeps user-hidden content visible to the agent.

