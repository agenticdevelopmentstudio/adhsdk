
ResizableSplit renders no user-facing text of its own — `header`, `top`, and `bottom` content come from the consumer, and the chevron is a pure icon — but `bottomLabel` defaults to the hardcoded English string `"Details"` when the consumer omits it. Consumers with localized UIs MUST pass a localized `bottomLabel`, or source the default from their own string table; the component does not localize it itself.

