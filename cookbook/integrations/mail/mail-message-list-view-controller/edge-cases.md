
- **Empty list**: With no messages the table has zero rows and the centered label shows (MUST). Covered by mail-list-016 and mail-list-017.
- **Row asked for after the list shrank**: The table reloads one main-queue hop after the list changes, so a layout pass in between can ask for a row that no longer exists; the list MUST return no view for it, as its source comment explains. Covered by mail-list-015.
- **Empty subject**: A message with an empty subject MUST show `(no subject)` (mail-list-009).
- **Unparseable date**: A date the model cannot parse MUST show as the original text (mail-list-008).
- **Selected id not listed**: When the selected id is not in `messages`, or is nil, the list MUST clear the table selection (mail-list-021).
- **Selection echo**: The list MUST suppress the selection callback while it applies the model's selection, so the model is not called back (mail-list-020).
- **Selection out of range**: In the selection callback, a selected row index outside `messages` MUST be sent to the model as no message (mail-list-034).
- **Repeated last-row display**: The list calls `loadMore()` every time the last row is shown while `hasMore` is true and does not guard against repeats itself; the model's `loadMore()` is a no-op while a page is loading and on the last page. The list SHOULD keep relying on that guard.
- **Load-more failure**: The list does nothing on a failed page load; the model sets `errorMessage`, and this controller shows no error of its own. The error is surfaced elsewhere in the mail window.
- **Boundary, one message**: With a single message, that row is both first and last, so showing it loads the next page when `hasMore` is true.
- **Concurrent access**: The controller and its model are main-actor isolated; model changes arrive on the main queue, and page loads run in unstructured tasks that call the main-actor model. The model drops pages answering an older list, so a late page cannot change the list under the user.
- **Offline or disconnected**: Not applicable to this controller: it makes no network call; it only displays what the model holds. Failures reach the user through the model's `errorMessage`.
- **Long text**: Long sender, subject and snippet text MUST truncate at the tail rather than wrap.

