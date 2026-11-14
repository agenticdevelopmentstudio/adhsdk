
The commit detail logs a failed diff at error level, by `GitClientError.logDescription` (case and fields, never git's output), under its own `Loggable` category; the other views log nothing, and the model logs failed reloads.

