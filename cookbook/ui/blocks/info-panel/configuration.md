
| Option | Type | Default | Description |
|---|---|---|---|
| `title` | `ReactNode` | — (required) | Header title. |
| `children` | `ReactNode` | — (required) | Body content. |
| `icon` | `ReactNode` | — | Leading glyph before the title (decorative, `aria-hidden`). |
| `titleAfter` | `ReactNode` | — | Rendered immediately after the title (e.g. a copy button). |
| `count` | `number` | — | Dim count after the title; hidden when absent or ≤ 0. |
| `center` | `ReactNode` | — | Centered header slot (e.g. a progress bar). |
| `actions` | `ReactNode` | — | Right-justified header slot (e.g. filter + gear). |
| `scroll` | `boolean` | `false` | Fill + scroll body; false = content-sized card. |
| `flex` | `string` | `scroll ? "1 1 0" : "0 0 auto"` | Outer flex shorthand. |
| `maxHeight` | `string \| number` | — | Outer max height. |
| `bodyPadding` | `string` | `scroll ? "8px 16px 10px" : "12px 16px"` | Body padding. |
| `bodyRef` | `Ref<HTMLDivElement>` | — | Ref to the scrolling body element. |
| `ariaLabel` | `string` | `title` if string | Accessible region name. |
| `className` / `style` | `string` / `CSSProperties` | — | Merged onto the outer `<section>`. |
| …rest | `Omit<HTMLAttributes<HTMLElement>, "title">` | — | Remaining host attributes (`data-*`, `id`, handlers) spread onto the outer `<section>`. |

`INFO_PANEL_HEADER_HEIGHT` (= 41) is exported so hosts can align non-`InfoPanel`
chrome to the same header baseline.

