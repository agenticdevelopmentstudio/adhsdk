
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Field | [adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a) | The grouped rows — each caption+control+hint/error that the group stacks | yes | Passed as `children`; the group applies `gap-3` between them |

The group title reuses the shared `fieldCaptionClass` from `@adh-sdk/ui/lib/typography`
(the same uppercase-mono caption treatment `Field` uses), so titles and field
captions stay visually identical. `trailing` is an arbitrary caller node
(status text, a `Button`, a badge) — not a fixed ingredient.

