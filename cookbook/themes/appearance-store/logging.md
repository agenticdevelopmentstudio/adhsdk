
Not applicable: the module makes no log call. The storage helpers swallow storage errors with a comment and no log, and the in-repo caller reports a fetch failure through its own `captureException`.

