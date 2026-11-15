
- **Data collected**: none; the renderer reads selectors from the store
  and writes them into the page showing.
- **Exposure to the page**: the page's own scripts can see the
  `__adk_hidden_items` element and so learn which selectors the user hides
  on that site. That is the cost of a style the page's style engine
  applies; the selectors were picked from that same page.
- **Agent exposure**: user-hidden content is absent from what the agent
  receives (MUST, see `user-hidden-hidden-from-agent`).

