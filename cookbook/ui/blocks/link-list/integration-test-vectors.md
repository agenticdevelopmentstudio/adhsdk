| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-row-per-link | three links | a `<ul>` with three items in order |
| T2 | link-title | a link with and without `href` | an anchor with `target="_blank"` and `rel` containing `noopener`, else plain text |
| T3 | render-icon | an image, a file and a url link | three decorative icons, one per kind |
| T4 | render-description | a link with a description | the description is shown muted |
| T5 | thumbnail-images | an image with and without `href`, a non-image with `href` | one lazy `<img alt="">` inside a link to the `href`; no other thumbnails |
| T6 | mark-missing | a missing link with `href` and `image` | struck-through dim title, "missing" label, no anchor, no `<img>` |
| T7 | show-empty | `links={[]}`, with and without `emptyLabel` | the label shown, no list |
| T8 | forward-class | `className="mt-2"` | the root carries it |
