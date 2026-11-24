
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` (list model) | history store | none — required | The store the model reads and writes. |
| `pageSize` (list model) | integer | 200 | The most visits listed, recent or filtered. |
| `filter` (list model) | string | empty | The filter text; trimmed before use. |
| `open` (panel) | callback taking an address | none — required | What the host does to open a visit. |
| Window identifier (window) | string | `web-history` | The fixed identifier the window saves and restores its frame and visibility under. |
| Record history (`browserRecordsHistory`) | boolean setting | on | Whether non-private panes record visits; shown under Privacy and Security › History. |
| Keep visits for (`browserHistoryRetention`) | setting | unchanged | How long visits are kept; shown under Privacy and Security › History. |
| Private browsing (`browserPrivateBrowsing`) | boolean setting | off | While on for a pane, that pane records nothing. |

