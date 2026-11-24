
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `block` | `LandingBlock` | required | The block to render; its `kind` selects the component |
| `key` | `number` | required | React key for the returned element |
| `pendingLabel` | `ReactNode` | `Screenshot coming soon` | Status line of a Shot with no image; the host's word for it when it has one |
| `paragraphs` | `ReactNode[]` | required | The list `prose` turns into `<p>` elements |
| `page` | `LandingPage` | required | The page whose sections `indexRows` lists |

