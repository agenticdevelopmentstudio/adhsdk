
Not applicable — this is a database-thread entry point, not a visual component. Its runtime lifecycle (booting, ready, failed) is captured under Behavioral Requirements: booting runs the startup sequence, `ready` is reached when `{ ready: true }` is posted, and `failed` is reached when `{ ready: false, error }` is posted or a precondition throws.

