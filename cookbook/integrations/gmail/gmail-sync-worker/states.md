
Not applicable — this is a synchronisation engine, not a visual component. Its runtime path is a sequence rather than a stored state machine: labels are refreshed, then a full or an incremental pass runs (an expired cursor turns the incremental pass into a full one), then the sync state is written once. The worker keeps no state between calls; the connection's cursor and status live in the store.

