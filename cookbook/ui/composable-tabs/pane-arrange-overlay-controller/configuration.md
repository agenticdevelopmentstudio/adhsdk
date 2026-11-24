
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nodeID` | `UUID` | required | The layout node naming the pane to the active-pane tracker. |
| `paneName` | `() -> String` | empty string | The pane's name shown by the overlay. |
| `canAdd` | `() -> Bool` | false | Whether the pane can add a neighbor. |
| `canRemove` | `() -> Bool` | false | Whether the pane can be removed. |
| `availableDirections` | `() -> Set<Direction>` | empty set | Directions the pane can move. |
| `offersAddRemove` | `Bool` | true | Whether the overlay offers add and remove. |
| `onAdd` | `() -> Void` | does nothing | Called when the overlay's add action is chosen. |
| `onRemove` | `() -> Void` | does nothing | Called when the overlay's remove action is chosen. |
| `onMove` | `(Direction) -> Void` | does nothing | Called with the direction for an overlay move or an arrow key. |
| `accessibilityID` (button) | `String` | required | Identifier of the title bar toggle, naming the window it sits in. |

