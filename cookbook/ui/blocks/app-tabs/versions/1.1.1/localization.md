
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Tab labels | User-provided | `label` (on `items` and `endItem`) is a ReactNode supplied by the consumer; the component performs no text generation or translation itself. |
| EndItem placement | `ml-auto` (LTR-only) | `endItem` is pushed to the trailing edge via the physical `ml-auto` utility, not a logical (`ms-auto` / `margin-inline-start`) one. In a `dir="rtl"` context this class does not mirror, so `endItem` stays on the visual right instead of moving to the trailing (left) edge. See Design Decisions and Platform Notes. |

