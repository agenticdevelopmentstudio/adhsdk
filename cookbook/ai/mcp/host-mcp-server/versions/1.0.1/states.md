
Not applicable — this is a protocol server, not a visual component. Its runtime states are described under Behavioral Requirements: idle (no current server), serving (a current server over a transport), and back to idle after `stop()` or after the message loop ends and `stop()` is called.

