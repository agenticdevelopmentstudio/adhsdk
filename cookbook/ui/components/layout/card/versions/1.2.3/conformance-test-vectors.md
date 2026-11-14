
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| card-001 | [export-six-slot-components](#requirements/export-six-slot-components) | `import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }` (UI Card family) | All six imports resolve to defined function exports. |
| card-002 | [render-div-root](#requirements/render-div-root) | Render each of the six UI Card family components with no props | Each renders a `<div>` as its outermost node. |
| card-003 | [set-data-slot-attribute](#requirements/set-data-slot-attribute) | Render `<Card />`, `<CardHeader />`, `<CardTitle />`, `<CardDescription />`, `<CardContent />`, `<CardFooter />` | Each rendered root `div` carries its matching `data-slot` value (`card`, `card-header`, `card-title`, `card-description`, `card-content`, `card-footer`). |
| card-004 | [merge-classname-prop](#requirements/merge-classname-prop) | `<Card className="extra-class" />` | The rendered root `div`'s `class` attribute contains both `extra-class` and the component's default classes (e.g. `rounded-xl`). |
| card-005 | [forward-rest-props](#requirements/forward-rest-props) | `<Card data-testid="x" />` | The rendered root `div` carries `data-testid="x"`. |
| card-006 | [compose-any-slot-subset](#requirements/compose-any-slot-subset) | `<Card><CardContent>Only content</CardContent></Card>` (Header/Title/Description/Footer omitted) | Renders without error, containing only the `CardContent` slot's markup. |
| card-007 | [always-renders-default-div](#requirements/always-renders-default-div) | `<Card />` (UI Card family, no children) | Renders an empty `<div data-slot="card">` carrying its default classes; nothing in source prevents an empty card. |
| card-008 | [card-corner-radius](#requirements/card-corner-radius) | `<Card />` | The rendered root `div`'s `class` attribute contains `rounded-xl`. |
| card-009 | [card-vertical-padding](#requirements/card-vertical-padding) | `<Card />` | The rendered root `div`'s `class` attribute contains `py-6` and no horizontal padding utility. |
| card-010 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardHeader />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-011 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardContent />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-012 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardFooter />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-013 | [card-children-gap](#requirements/card-children-gap) | `<Card />` | The rendered root `div`'s `class` attribute contains `gap-6`. |
| card-014 | [header-children-gap](#requirements/header-children-gap) | `<CardHeader />` | The rendered root `div`'s `class` attribute contains `gap-1.5`. |
| card-015 | [title-font-weight](#requirements/title-font-weight) | `<CardTitle />` | The rendered root `div`'s `class` attribute contains `font-semibold` and `leading-none`. |
| card-016 | [description-font-size](#requirements/description-font-size) | `<CardDescription />` | The rendered root `div`'s `class` attribute contains `text-sm`. |
| card-017 | [card-background](#requirements/card-background) | `<Card />` | The rendered root `div`'s `class` attribute contains `bg-apt-bg`. |
| card-018 | [card-text-color](#requirements/card-text-color) | `<Card />` | The rendered root `div`'s `class` attribute contains `text-apt-text`. |
| card-019 | [card-text-color](#requirements/card-text-color) | `<CardTitle />` | The rendered root `div`'s `class` attribute contains `text-apt-text`. |
| card-020 | [description-text-color](#requirements/description-text-color) | `<CardDescription />` | The rendered root `div`'s `class` attribute contains `text-apt-text-muted`. |
| card-021 | [card-border](#requirements/card-border) | `<Card />` | The rendered root `div`'s `class` attribute contains `border` and `border-apt-border`. |
| card-022 | [card-shadow](#requirements/card-shadow) | `<Card />` | The rendered root `div`'s `class` attribute contains `shadow-sm`. |

