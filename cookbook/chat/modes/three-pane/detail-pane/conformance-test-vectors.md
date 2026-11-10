
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detail-001 | header, literal-ui-strings | pane rendered | Header element contains the literal text "Details" |
| detail-002 | conditional-content | topic = null | Content area renders empty (no topic title/description/images/links) |
| detail-003 | title | topic = {title: "Test Topic", ...} | Title element renders with text "Test Topic" |
| detail-004 | optional-description | topic = {description: "Test desc", ...} | Description element renders below title |
| detail-005 | optional-description | topic = {description: "", ...} | Description element does not render |
| detail-006 | images | topic = {images: [{src: "/img.jpg", alt: "Alt text"}], ...} | Image element renders with src="/img.jpg" and alt="Alt text" |
| detail-007 | images | topic = {images: [{src: "/img.jpg"}], ...} | Image element renders with alt="" |
| detail-008 | image-load-callback | image loads + onImageLoad provided | onImageLoad callback is invoked |
| detail-009 | links-section, literal-ui-strings | topic = {links: [{label: "Link1", url: "http://example.com"}], ...} | Links section renders with the literal label "Links" and a clickable link with text "Link1" |
| detail-010 | link-properties | topic = {links: [{label: "Link1", url: "http://example.com"}], ...} | Link element has target="_blank" and rel="noopener noreferrer" |
| detail-011 | link-properties | topic = {links: [{label: "", url: "http://example.com"}], ...} | Link element displays URL text "http://example.com" |
| detail-012 | visibility-state | visible = true | Root element has class "pc-pane-visible" |
| detail-013 | visibility-state | visible = false | Root element has class "pc-pane-hidden" |
| detail-014 | connector-anchor | topic = {messageIndex: 5, ...}, rendered inside a `ConnectorRegistryProvider` | ConnectorAnchor element renders with `data-connector-anchor="panel-5-in"` (no `id` attribute) |
| detail-015 | content-mounted-when-hidden | topic present, rendered with visible = true, then re-rendered with visible = false | Title, description, image and link elements are all still present in the DOM; the root element has no `inert`, `aria-hidden`, or `tabindex` attribute |
| detail-016 | focus-untouched | topic with one link, visible = true; focus that link, then re-render with visible = false | `document.activeElement` is still the link element; the component issues no focus() call |
| detail-017 | no-analytics | topic present; render, load an image, click a link, toggle visible | No analytics event is dispatched by the component; the module references no analytics client |
| detail-018 | no-logging | topic present; render, load an image, toggle visible, render with topic = null | No console or logger output is produced by the component |
| detail-019 | topic-prop | topic = {title: "T", description: "", links: [], images: [], messageIndex: 0} (minimal valid Topic), rendered standalone with no `ConnectorRegistryProvider` | Component renders without error; per conditional-content, only the title renders — the connector anchor renders nothing, because ConnectorAnchor requires a `ConnectorRegistryProvider` |
| detail-020 | ref-forwarding | a ref object is passed to the component | `ref.current` is the root `HTMLDivElement` |
| detail-021 | connector-anchor | topic = null | No ConnectorAnchor element renders; no element carries a `data-connector-anchor` attribute |

