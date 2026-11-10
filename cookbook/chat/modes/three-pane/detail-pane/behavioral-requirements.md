
The pane's data model:

**Topic**

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | |
| `description` | string | yes | empty string is treated as absent — see **conditional-content** |
| `links` | array of TopicLink | yes | may be empty |
| `images` | array of TopicImage | yes | may be empty |
| `messageIndex` | number | yes | used to build the connector anchor's `data-connector-anchor` value — see **connector-anchor** |

**TopicLink**

| Field | Type | Required | Notes |
|---|---|---|---|
| `label` | string | yes | may be empty — falls back to `url`, see **link-properties** |
| `url` | string | yes | |

**TopicImage**

| Field | Type | Required | Notes |
|---|---|---|---|
| `src` | string | yes | |
| `alt` | string | no | defaults to an empty string when omitted — see **images** |

The `topic` prop itself is either a `Topic` object or `null`.

- **header**: The pane MUST render a fixed header labeled "Details" at the top of the panel.
- **topic-prop**: The pane MUST accept a `topic` prop whose value is either a `Topic` object or `null`.
- **conditional-content**: When `topic` is null, the pane MUST render an empty content area. When `topic` is provided, the pane MUST render all non-empty fields from the topic data.
- **title**: When a topic is present, the pane MUST render the topic's title as a distinct visual element.
- **optional-description**: When a topic is present and has a non-empty description, the pane MUST render the description below the title.
- **images**: When a topic is present and has images, the pane MUST render each image with its `src` attribute. If an image lacks an `alt` attribute, the pane MUST use an empty string.
- **image-load-callback**: When an image finishes loading, the pane MUST call the optional `onImageLoad` callback if provided.
- **links-section**: When a topic is present and has links, the pane MUST render a "Links" label followed by a list of clickable links.
- **link-properties**: Each link MUST open in a new tab (target="_blank") with `rel="noopener noreferrer"`. If a link has no label, the pane MUST display the URL as the link text.
- **visibility-state**: The pane MUST accept a `visible` prop and apply a CSS class indicating visibility state (`pc-pane-visible` when true, `pc-pane-hidden` when false).
- **content-mounted-when-hidden**: When `visible` is false, the pane MUST keep the header and all topic content mounted in the DOM. It MUST NOT unmount the subtree and MUST NOT apply `inert`, `aria-hidden`, or a negative `tabIndex` to the root element or its descendants.
- **focus-untouched**: The pane MUST NOT set, move, or restore focus when `visible` changes. Changing `visible` MUST change only the root element's class name and MUST leave the active element exactly as it was.
- **literal-ui-strings**: The pane MUST render "Details" and "Links" as literal English text; today it does so without any localization key, catalog, or translation hook. This absence is a known gap (see Localization), not a permanent constraint — a future revision that introduces localization for these strings SHOULD do so without being treated as breaking this requirement.
- **ref-forwarding**: The pane MUST support ref forwarding to expose the root `HTMLDivElement`.
- **connector-anchor**: When `topic` is present, the pane MUST render a ConnectorAnchor element carrying a `data-connector-anchor` attribute constructed from the message index in the format `panel-{messageIndex}-in` (not a DOM `id`), provided a `ConnectorRegistryProvider` is present in the tree — without one, ConnectorAnchor renders nothing. When `topic` is null, the pane MUST NOT render a ConnectorAnchor element at all.
- **header-semantics**: The pane SHOULD render the header using a heading element (e.g., an `<h2>`) and the root SHOULD carry a landmark role (e.g., `role="complementary"`) when used as a primary content region. The current implementation renders both as plain `div`s with no heading or landmark semantics (see Compliance: `semantic-markup`).
- **no-analytics**: The pane MUST NOT emit analytics events. A consuming application that needs instrumentation MUST add it at the call site — for example by wrapping the `onImageLoad` callback it passes in, by observing the `visible` prop it controls, or by attaching its own handler to the rendered links.
- **no-logging**: The pane MUST NOT write log messages. A consuming application that needs diagnostics MUST emit them at the call site, where the `topic` and `visible` props and the `onImageLoad` callback are already available.

