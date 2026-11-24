
No test beside the source exercises this view. These vectors are derived from
the source and untested.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| table-filling-001 | holds-one-card, card-pinned-top | Build with a card and lay out at 600 by 400 | `card` is the given card; its frame starts at the top edge and spans 600 points |
| table-filling-002 | table-fills-slack | A card 250 points tall in a view 400 tall | After layout the card's `tableHeight` is 150 points greater and the card's height is 400 |
| table-filling-003 | shrinks-with-view | The view goes from 400 to 300 points tall | `tableHeight` drops by 100 points |
| table-filling-004 | slack-threshold | A view 0.4 points taller than the card | `tableHeight` is unchanged |
| table-filling-005 | slack-threshold | A view 0.6 points taller than the card | `tableHeight` grows by 0.6 |
| table-filling-006 | minimum-height | Default initializer; read the view's fitting height | At least 120 points |
| table-filling-007 | minimum-height | `minimumHeight` of 200 | At least 200 points |
| table-filling-008 | card-floor | The view is much shorter than one row plus header | The card's `tableHeight` is one row, not less, and the view's minimum height still holds |
| table-filling-009 | card-autolayout | After building | The card does not translate autoresizing masks into constraints |

