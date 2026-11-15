
- **Empty or missing values**: An empty list of sessions renders as `none` (MUST); a nil `previousTick` or `summary` omits its line (MUST); an empty `summary` still adds an empty line (MUST, as stated in tick-text-summary).
- **Empty strings in ids and titles**: Rendered as given; the type does not validate them (MUST, text-verbatim-ids). An empty job id still produces the key `tick:`, which every other empty-id tick shares.
- **Same id, different titles**: Two idle events with the same session id and different titles share a key (`key-ignores-payload`); what the queue then keeps is specified by Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150)).
- **Ids containing separators**: An id that contains a colon is not escaped. Keys of different kinds cannot collide because each kind has its own prefix, and the separator is not parsed back.
- **Repeated owner messages**: Identical owner messages never collapse; each starts its own turn (MUST).
- **Lifecycle notices**: A lifecycle event never collapses with another lifecycle event, including two of the same case (MUST).
- **Date rendering**: `previousTick` is always rendered in UTC regardless of the device time zone (MUST, tick-text-previous).
- **Concurrent access, network, timeouts, offline**: Not applicable — the type is immutable and does no I/O; ordering and concurrency belong to `PartnerTurnQueue` and the controller that owns it.
- **Boundary values**: Not applicable — there are no numeric limits; string length is unbounded.

