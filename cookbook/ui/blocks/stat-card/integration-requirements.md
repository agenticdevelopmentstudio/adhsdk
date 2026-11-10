
- **render-infopanel-shell**: The card MUST render as an `InfoPanel` whose title is `title` and whose leading glyph is `icon`, exposing the card as a labeled region named by `title`.
- **title-as-accessible-name**: `title` MUST be a plain string, so the region InfoPanel names from it carries a reliable accessible name; a non-string `title` is not guaranteed to produce a meaningful one.
- **place-link-in-actions**: When `link` is provided, the card MUST render an `ExternalLink` to `link.href` labeled `link.label` in the InfoPanel actions slot, and MUST omit the actions slot when both `link` and `actions` are absent.
- **render-actions-after-link**: When `actions` is provided, the card MUST render it in the InfoPanel actions slot, after the deep link when both are present.
- **spread-host-attributes**: The card MUST pass remaining host attributes (`data-*`, `id`, handlers) through to the InfoPanel root `<section>`, so hosts can tag the card without a wrapper element.
- **render-a-statrow-per-stat**: The card MUST render one `StatRow` per `stats[]` entry, passing that entry's `label`, `value`, and `tone`.
- **render-children-after-rows**: The card MUST render `children` after the stat rows, within the same body stack.
- **render-footnote-when-present**: The card MUST render `footnote` as a muted mono caption after the children — and as the last item in the body stack even when there are no children or no `stats` — and MUST omit it when `footnote` is null/undefined.
- **stack-body-vertically**: The card MUST arrange the rows, children, and footnote in a single vertical `gap-2.5` column.
- **forward-classname**: The card MUST forward `className` onto the InfoPanel outer element.

