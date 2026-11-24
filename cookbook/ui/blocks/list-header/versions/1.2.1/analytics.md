
Not applicable: ListHeader is a presentational toolbar. It emits no analytics events
of its own. Consumers that need to track filter changes or actions SHOULD attach
their own handlers to `onChange` and the action buttons' click events and emit
events at that level.

