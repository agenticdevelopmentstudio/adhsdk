
The commit detail, the diff, the blame and the file history each log a failed load (diff, blame, history, or a side's contents) at error level, by `GitClientError.logDescription` (case and fields, never git's output), under their own `Loggable` categories; `GitSyntaxColoring` logs a highlighter error by its type; the other views log nothing, and the model logs failed reloads.

