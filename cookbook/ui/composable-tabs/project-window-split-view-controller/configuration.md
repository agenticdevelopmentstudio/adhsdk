
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| content | view controller | required | The window content, laid out from the safe area |
| shelf | shelf controller or none | none | The shelf; none gives a content-only window |
| onShelfVisibilityChange | callback | none | Called when a slide begins and ends, on an immediate change, and when an adopted layout changes visibility |
| onShelfWillMove | callback | none | Called as the shelf's width is about to change beside the content |
| onShelfDidMove | callback | none | Called when that movement has finished |
| Persisted shelf visibility | setting | hidden | Remembered across launches and shared by every project window |
| Persisted shelf width | setting, points | 240 | The width the reader last gave the shelf |
| Shelf width bounds | constants, points | 180 through 480 | Fixed |
| Content minimum width | constant, points | 300 | Fixed |
| Slide duration | constant | 0.2 seconds | Fixed |
| Drag settle delay | constant | 250 milliseconds | Fixed |

