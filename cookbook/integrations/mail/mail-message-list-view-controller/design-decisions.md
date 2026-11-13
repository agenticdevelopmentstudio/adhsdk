
**Decision**: The controller reads and calls the model only; it holds no mail state and no networking.
**Rationale**: The model's own comment says every action goes through it, so it is the tested unit and the view controllers only read it and call it.
**Approved**: pending

**Decision**: Row height is fixed at 68 points and automatic row heights are off.
**Rationale**: The row is always three fixed lines of two fonts, and tail truncation keeps its height constant, so measuring is not needed.
**Approved**: pending

**Decision**: The list guards against a row index the model's `messages` no longer has.
**Rationale**: The source comment states the table reloads a main-queue hop after the list changes, so a layout pass in between can ask for a row the shrunk list no longer has.
**Approved**: pending

**Decision**: A flag, `applyingSelection`, silences the selection callback while the model's selection is applied.
**Rationale**: Without it, applying the model's selection would call `select(messageId:)` back and loop between table and model.
**Approved**: pending

**Decision**: Next-page loading is triggered from the last row's view creation, with no guard in the controller.
**Rationale**: The model's `loadMore()` is a no-op while a page loads and on the last page, so repeated calls cost nothing. The trigger fires when the row view is requested, so it depends on the table asking for the last row. The SHOULD on keeping that reliance is a default: a controller-side guard would duplicate the model's flag, and a platform whose list control re-requests rows more often might add its own.
**Approved**: pending
