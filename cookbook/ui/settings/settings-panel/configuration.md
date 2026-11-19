
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `descriptor` | Descriptor (optional) | none | Passed at construction. When supplied, retained as-is (see **descriptor-retention**); when omitted, a default descriptor (empty title) is constructed instead (see **default-descriptor**). |
| `descriptor.subtitle` | Text (optional, observable) | none | A field of the descriptor, not a construction option of the panel: a second line of row metadata, settable at any time (see **descriptor-subtitle-default** and **descriptor-subtitle-observable**); the settings panel list draws it. |

