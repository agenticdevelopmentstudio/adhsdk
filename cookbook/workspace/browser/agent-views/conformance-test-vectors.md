
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-views-001 | three-segment-control, segment-tooltips | Open a browser pane with the privacy toolbar shown | The control has three icon segments in the order Website, Agent preview, Agent source, single selection, each with its tooltip text |
| agent-views-002 | default-website, website-shows-live-page | Open a new tab | Website is selected and the live page is shown |
| agent-views-003 | per-tab-not-persisted | Tab A in Agent source, tab B in Website; switch between them | Each tab shows its own mode and content |
| agent-views-004 | per-tab-not-persisted | Put a tab in Agent preview; close and restore the pane | The restored tab is in Website mode |
| agent-views-005 | preview-replaces-content-read-only, views-show-gatekeeper-output-only | Select Agent preview on a page | The content is a web view whose document is the gatekeeper's HTML for that page |
| agent-views-006 | preview-javascript-off | Inspect the preview's configuration | Page JavaScript is disabled |
| agent-views-007 | preview-blocks-network | Preview's content rules; an HTML page containing an image with a source | A block-every-URL rule list is installed; no request leaves the preview, and the gatekeeper's HTML holds no source attribute |
| agent-views-008 | preview-no-navigation | Click a link in the preview | The navigation is cancelled; the preview still shows the same document |
| agent-views-009 | preview-paints-under-quiet-presentation | Development build under quiet presentation; photograph the preview's window | The shot shows the preview's content, not a blank view |
| agent-views-010 | source-same-html | Select Agent source | The text view's text equals the gatekeeper's HTML exactly; it is not editable |
| agent-views-011 | source-highlighted | Source text `<p data-adk-ref="e1">Hi</p>` | The tag, the attribute name, the attribute value and "Hi" carry four distinct colors; the font is monospaced |
| agent-views-012 | unavailable-shown-as-reason | The privacy words cannot be read; select Agent preview, then Agent source | The preview shows only the "Agent view unavailable: …" paragraph; the source is that paragraph's HTML |
| agent-views-013 | refresh-triggers | In Agent preview, add an agent-list entry that hides a heading | The preview rebuilds and the heading is gone |
| agent-views-014 | refresh-triggers | In Agent source, navigate to another page; separately change a privacy word; separately turn Hide Images on | Each change rebuilds the source to match the new gatekeeper output |
| agent-views-015 | refresh-coalesced | Fire five triggers within 100 milliseconds | Exactly one rebuild runs |
| agent-views-016 | website-mode-restores-page | Fill a text field on the page, switch to Agent preview, then back to Website | The live page shows again with the typed text, not reloaded |
| agent-views-017 | preview-no-navigation | Show two pages in the preview back to back, before WebKit asks about the first load | Both loads are allowed and the preview shows the second page; after it finishes, a further `about:blank` navigation is cancelled |
| agent-views-018 | entering-from-website-blank | In Agent preview, switch to Website, navigate to another page, then switch to Agent source | The source shows the blank page until the rebuild lands, then the new page; the earlier page is never shown |
| agent-views-019 | entering-from-website-blank | In Agent preview showing a page, switch to Agent source | The source shows that page's HTML at once, before the rebuild lands |
| agent-views-020 | source-highlighted | Show a large page in Agent source | The text appears at once in the text color; the highlight colors follow when the lex lands; showing the same HTML again changes nothing |

