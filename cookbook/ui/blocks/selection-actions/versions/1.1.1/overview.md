
Selection Actions is a toolbar component that renders a configurable strip of action buttons for operating on selected items from a list. Each action is a button that receives the array of currently selected item IDs. The component optionally includes a destructive Delete button that requires user confirmation via a modal before executing the delete callback. Actions without selection requirements (such as "New" actions) remain enabled when no items are selected; actions with selection requirements become disabled. Dividers can visually group related actions.

The component renders no container of its own — it is designed to be placed in a toolbar context such as a `ListHeader`'s `actions` slot, which provides the visual styling and layout.

