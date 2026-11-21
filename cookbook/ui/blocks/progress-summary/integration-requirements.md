
- **render-count-text**: The block MUST render the text "`{done} of {total} {label} done`", with `label` defaulting to "items".
- **render-percent**: The block MUST render the percentage as "`{percent}%`" where percent is `floor(done*100/total)`, and 0 when `total` is 0.
- **label-bar**: The block MUST render a `Progress` bar whose value is the percentage and whose `aria-label` is the count sentence.
- **green-when-complete**: The bar's indicator MUST use the `bg-apt-green` token class when `done === total` and `total > 0`, and MUST NOT otherwise.
- **forward-host-attributes**: The block MUST forward `className` and remaining host attributes to its root element.
