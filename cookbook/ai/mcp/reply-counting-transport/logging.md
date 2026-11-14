
Not applicable: the transport's logger is a deliberate no-op (`SwiftLogNoOpLogHandler`), so it logs nothing. The stdio serving path that calls it (`serveUntilDrained`) logs a warning with the unanswered count when the deadline passes with replies still owed.

