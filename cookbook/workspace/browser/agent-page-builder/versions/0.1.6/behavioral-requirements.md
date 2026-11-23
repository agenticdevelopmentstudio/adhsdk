
- **single-gatekeeper**: The component MUST be the only source of page
  content for every agent page read — the snapshot, text and find tools,
  the references click, type, fill, select and hover resolve, and the text
  a wait condition is checked against — for the in-app chats and the
  external tool server alike; agent-facing tools MUST NOT read page content
  by any other route except the raw-page tools in the situations
  `raw-page-tools-refused-when-filtered` allows.
- **always-runs**: The component MUST run for every agent page read
  whatever the privacy settings are; there MUST be no branch on any
  privacy setting that chooses whether to use it. With every privacy
  feature off it MUST still enforce the allowlist and skip hidden content.
- **built-up-not-trimmed**: The component MUST construct its result only
  from nodes the walker emits and it has re-validated; it MUST NOT copy,
  serialize or pass through any markup, script, style or attribute of the
  live page that it did not itself construct.
- **allowlist-defined-once**: The allowlist of node kinds and per-kind
  attributes MUST be defined once, on the host side, and MUST be passed to
  the walker as an argument of each walk; the walker MUST NOT carry its own
  copy.
- **walker-emits-allowlisted-only**: The walker MUST emit only nodes whose
  kind is on the allowlist it was given and, on each node, only attributes
  the allowlist permits for that kind, and MUST give every emitted node a
  reference.
- **walker-skips-hidden-nodes**: The walker MUST NOT visit a node, or any
  node beneath it, whose computed display is none, whose computed
  visibility is hidden, that carries the `hidden` attribute, or that
  carries `aria-hidden="true"`.
- **user-hidden-items-hidden-from-agent**: Because an item hidden by the
  user's "hide distracting items" list is hidden by a display-none rule,
  the walker MUST NOT visit it either; the agent list MUST be the only way
  to hide something from the agent alone.
- **walker-skips-agent-list**: The walker MUST NOT visit a node, or any
  node beneath it, that matches any enabled agent-list selector for the
  page's site.
- **invalid-exclude-selector-fails-closed**: An agent-list selector the
  document cannot evaluate would exclude nothing, so the walk MUST be
  refused: the walker MUST answer `{"error":"agent-list"}` and the
  component MUST return the unavailable page, showing nothing of the page.
- **scope-within-walk**: A scope argument on the snapshot or text tools
  MUST be a reference from the reference table, never a CSS selector, and
  MUST select a subtree within the gatekeeper's own walk, with agent-list
  exclusion still applied inside it. A scope that names nothing, whose
  element is gone, or whose element or any of its ancestors is withheld
  (hidden, or matching an enabled agent-list selector) MUST give the whole
  page, exactly as a reference that names nothing does, never an empty
  root or an error, so the answer never tells the agent whether a withheld
  element exists.
- **withheld-refs-stale**: A reference to an element the last walk
  excluded by the agent list, or to anything beneath it, MUST
  resolve as stale for every action and as no scope, whichever walk handed
  it out, and every reference MUST go stale on any change to the
  hidden-items store, because a reference handed out before its element
  joined the agent list must not stay usable until the next snapshot.
- **unknown-kind-dropped-with-subtree**: The component MUST drop a node
  whose kind is not on the allowlist, or that it cannot classify, together
  with its whole subtree.
- **unlisted-attribute-dropped**: The component MUST drop every attribute
  of a node that the allowlist does not permit for that node's kind.
- **href-sanitized**: The component MUST keep a link's `href` only when it
  is an absolute `http` or `https` address after a relative address is
  resolved against the page's address; any other address (including
  `javascript:`, `data:` and anything that does not parse) MUST be dropped.
- **concealed-before-insertion**: The component MUST pass every string —
  node text, value, page title, every attribute value and every `href` —
  through the privacy concealment in force before the node holding it is
  created, so no real privacy word reaches the result in any rendering.
  Text that a rendering joins from several pieces — a subtree's text read
  the `textContent` way for a generic line, a name taken from content or
  an option, and a run of text pieces in the text and HTML renderings —
  MUST be joined from the unconcealed pieces, then collapsed (line by line,
  per text-keeps-line-structure) and trimmed once, then concealed once as a whole, never assembled from pieces
  concealed one by one, so a privacy word split across inline elements
  (`Ac<b>me</b>`) is still concealed.
- **text-pieces-keep-boundary-space**: The walker MUST send each text
  piece with its whitespace runs collapsed to one space but its leading
  and trailing space kept, and MUST keep a whitespace-only text node as one
  space between two contributions (never leading, trailing or doubled), so
  joined text keeps the word boundary `innerText` reads: `Buy <b>now</b>`
  MUST read "Buy now" in the text, HTML and content-name renderings, while
  the snapshot tree MUST still print each piece trimmed, as today.
- **text-keeps-line-structure**: The walker MUST send the line breaks
  `innerText` reads as a newline in the text it emits: a shown `<br>`, the
  edges of a block box it flattens or reads through (a `div`, any element
  whose computed display is not inline, `contents` or ruby; a table cell's
  edges are a space), and the newlines of a text node whose element
  preserves them (`<pre>`, `white-space: pre*`). The text rendering MUST
  start a new line at each, dropping empty lines; the HTML rendering MUST
  write each run of them as one `<br>` carrying the node's `data-adk-ref`;
  the snapshot tree and every name MUST read them as a space. Text holding
  a break MUST be concealed with its breaks kept only when that equals,
  breaks read as spaces, the text concealed as one line; otherwise it MUST
  be the one-line concealment, so a break never carries a privacy word
  (`Acme<br>Corp` for "Acme Corp") past the filter.
- **hide-images**: When the Hide Images setting is on, the component MUST
  drop every image node; when it is off, an image MUST enter the result
  only as its alternative text, never as an image source. With Hide
  Images on the walker MUST NOT visit an image (an `img` element or the
  `img` role) at all, so an image takes no `eN` reference. The value MUST
  be the pane's effective Hide Images — its own override, else the global
  value — and the agent tools and the pane's Agent preview and Agent
  source MUST build under that same value.
- **value-kept-only-for-form-controls**: The component MUST keep a node's
  value only for text fields, text areas, selects, checkboxes and radio
  buttons, and MUST never keep the value of a password field. The snapshot
  rendering MUST print the value of a text field, text area or select as
  today's snapshot does: an empty value is printed as none, tested before
  whitespace is collapsed, so a value of only whitespace is kept and
  printed as `[value=""]`; otherwise whitespace collapsed and cut at 50
  characters. An element with the `slider` or
  `spinbutton` role that is not an `input` reaches the component as a text
  field of type `range` or `number` whose value is its `aria-valuenow`, and
  that value MUST be kept and printed the same way.
- **fail-closed-on-walker-failure**: When the walker throws, does not
  finish within its timeout (1500 milliseconds by default), or returns a
  payload that does not decode, the component MUST return an empty page —
  no root — carrying a reason that begins `Agent view unavailable: `, and
  MUST NOT return any page content.
- **fail-closed-on-vault**: When the privacy concealment is unavailable
  (the words cannot be read) or conflicting (a stand-in holds a real
  word), the component MUST return an empty page carrying a reason that
  begins `Agent view unavailable: ` before it reads the payload, even when
  the payload is valid.
- **no-partial-content-on-failure**: On any failure the component MUST
  return the empty page alone and MUST NOT return any part of the page
  built before the failure was found.
- **one-value-three-renderings**: The component MUST produce one
  immutable page value from which the snapshot tree, the text and the
  HTML are all rendered; renderings MUST NOT read the page or the walker's
  payload on its own.
- **snapshot-tool-contract-unchanged**: The snapshot rendering MUST
  reproduce today's tree format, line for line, for the equivalent tree,
  and MUST honor the existing options — interactive only, depth, scope,
  include URLs, delta — and generation-stamped references; existing tool
  descriptions MUST remain true. As today, a depth of 0 or less MUST mean
  no limit, and the text a generic element collapses to, or a button,
  link, heading, cell or option is named by, MUST be its subtree's text
  concatenated with no separator, as an element's `textContent` is
  (`a<b>b</b>` gives "ab").
- **printed-refs-have-no-gaps**: Only a node the snapshot prints with a
  reference MUST take one of the page's element numbers (`eN`). A
  paragraph or label that is not interactive, which prints as text with no
  reference, MUST take a walk-local reference (`g1`, `g2`, …) instead, and
  a role that is dropped (flattened into its parent) MUST take none, so the
  `eN` references a snapshot prints run without gaps.
- **refs-drive-actions**: Every reference in the result MUST be one that
  click, type, fill, select and hover resolve to the same element.
- **selector-recorded-per-node**: Each node MUST record a selector for its
  element at build time, so a later pick on that node in the Agent preview
  can be mapped back to the page.
- **html-rendering-safe**: The HTML rendering MUST escape every string,
  MUST emit only elements it maps from node kinds, MUST put the node's
  reference on each element it emits as `data-adk-ref`, MUST emit no
  `script` element and no `style` attribute, and MUST render an image as a
  text placeholder holding its alternative text, never as an element with
  a source.
- **unavailable-page-renders-reason**: An unavailable page MUST render as
  its reason alone — one paragraph in the HTML, the reason as the text and
  as the tool result.
- **unavailable-reason-is-the-result**: When the page is unavailable, the
  snapshot, text and find tools MUST return its reason as their result,
  not an error that could lead a caller to retry against the raw page.
- **string-path**: The component's string path MUST return a string
  unchanged when agent privacy is off, concealed with the privacy words
  when it is on, and empty when the vault is unavailable or conflicting.
- **reply-concealed-with-start-and-end-words**: A tool reply or error
  MUST be concealed with the privacy in force when the call started and the
  privacy in force when it returns, together: off on one side gives the
  other, an unavailable or conflicting side wins, and two sets of words give
  every pair of both, checked again for conflicts. A setting turned off
  while the call ran MUST NOT unconceal the reply.
- **raw-page-tools-refused-when-filtered**: The screenshot, click-at and
  evaluate tools, which see the page without the gatekeeper, MUST be
  refused when agent privacy is on or when the page's site has any enabled
  agent-list entry; the agent-list refusal MUST say "This site has items
  hidden from the agent, so tools that see the raw page are refused here."
- **raw-page-tools-allowed-when-unfiltered**: With agent privacy off and no
  enabled agent-list entry for the site, the screenshot, click-at and
  evaluate tools MUST NOT be refused by this component.
- **console-refused-under-privacy**: The console tool MUST be refused
  while agent privacy is on, with the sentence "Agent Privacy is on for
  this browser pane, so console output is not shared."
- **wait-for-uses-agent-text**: A wait condition on text MUST be evaluated
  against the result's text, never the live document, so text present only
  in excluded or hidden content never satisfies it.
- **find-uses-agent-page**: The find tool MUST search the result's text and
  return references from the result.
- **titles-dialogs-focus-through-string-path**: Page titles in the pane
  list and in action replies, script dialog messages, and the
  focused-element description in action replies MUST pass through the
  string path; a focused element whose reference is not in the current
  result MUST be omitted from the reply.
- **history-through-string-path**: Every title and address the history
  tool returns MUST pass through the string path.

