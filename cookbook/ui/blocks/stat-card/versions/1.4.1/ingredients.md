
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| InfoPanel | [adhsdk.ingredient.ui.blocks.info-panel](cookbook:2ad7c681-6a9e-43ae-a9d9-b448939d3455) | The card shell — bordered/rounded frame with the standard header (icon + title) and a content-sized body | yes | `title`, `icon`, `actions` (the link + extra `actions`), `className` and remaining host attributes forwarded; default content-sized (no `scroll`) |
| StatRow | [adhsdk.ingredient.ui.components.display.stat](cookbook:bba42d5f-8a52-487f-88c5-4f988dfa714b) | One label/value figure per `stats[]` entry, in the body stack | yes (when `stats[]` non-empty) | `label`, `value`, `tone` passed through from each `StatCardStat` |
| ExternalLink | [adhsdk.ingredient.ui.components.actions.external-link](cookbook:b329d08b-9812-47d0-8094-516359d82d19) | The "{label} ↗" deep link into the source tool, placed in the InfoPanel actions slot | no (only when `link` given) | `href` = `link.href`, children = `link.label`; opens a new tab (noopener) |

The body-stack container, the footnote treatment, and the `stats[]`→rows mapping are
the only things this block owns; `StatCardStat` (`{ label, value, tone }`) is exported
alongside the component.

