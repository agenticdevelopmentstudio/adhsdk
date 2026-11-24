
- **three-segment-control**: The view switch MUST be a single-selection
  control of three icon segments in the privacy toolbar, in the order
  Website, Agent preview, Agent source.
- **segment-tooltips**: Each segment MUST carry a tooltip: "Website — the
  page as it is", "Agent preview — what the agent can see, with privacy
  filters applied", and "Agent source — the page the agent receives, as
  source".
- **default-website**: A tab MUST start in Website mode.
- **per-tab-not-persisted**: The mode MUST belong to one tab: switching
  tabs MUST show each tab's own mode in the control and its content, and
  the mode MUST NOT be saved, so a tab that is reopened or restored starts
  in Website mode.
- **website-shows-live-page**: In Website mode the tab's content MUST be
  the live page, unchanged by this component.
- **views-show-gatekeeper-output-only**: Both agent views MUST obtain
  their content only from the agent gatekeeper's single page entry point,
  as its HTML rendering, and MUST NOT read the live page any other way.
- **preview-replaces-content-read-only**: In Agent preview mode the tab's
  content MUST be replaced by a read-only web view showing the
  gatekeeper's HTML.
- **preview-javascript-off**: The preview MUST load with page JavaScript
  disabled.
- **preview-blocks-network**: The preview MUST block every network load,
  for every URL and resource type.
- **preview-no-navigation**: The preview MUST cancel every navigation
  other than its own loads of the gatekeeper's HTML, including link
  clicks and every subframe load. Each own load MUST let exactly one
  main-frame load of `about:blank` through, so two loads started in quick
  succession are both answered and the newest page is shown; the
  allowance MUST be cleared when the latest own load finishes or fails,
  so none outlives the newest load, and an own load that starts no
  navigation MUST give its allowance back at once.
- **preview-paints-under-quiet-presentation**: In development builds the
  preview MUST keep painting while its window is reported occluded, so it
  can be photographed under quiet presentation.
- **source-same-html**: In Agent source mode the tab's content MUST be a
  read-only text view whose text is exactly the gatekeeper's HTML.
- **source-highlighted**: The source view MUST highlight tags, attribute
  names, attribute values and text in distinct theme colors, in a
  monospaced font. It MUST show the HTML at once in the text color and
  apply the highlighting when the lex, run off the main thread, lands; a
  lex for HTML no longer shown MUST be discarded, and the same HTML again
  MUST change nothing.
- **unavailable-shown-as-reason**: When the gatekeeper returns an
  unavailable page, both agent views MUST show its reason and no page
  content.
- **refresh-triggers**: An agent view MUST rebuild after the tab finishes
  a navigation, after any agent privacy setting for the pane changes,
  after the privacy words change, and after the site's agent list changes.
- **refresh-coalesced**: Triggers arriving within 250 milliseconds of one
  another MUST produce a single rebuild.
- **website-mode-restores-page**: Switching back to Website mode MUST show
  the live page again, in the state it was in, without reloading it.
- **entering-from-website-blank**: Switching from Website to an agent mode
  MUST show the blank page until the rebuild lands, never the last agent
  page, since the page, its address or its agent list may have changed
  while the Website was shown; switching between the two agent modes MUST
  show the current agent page at once while the rebuild runs.

