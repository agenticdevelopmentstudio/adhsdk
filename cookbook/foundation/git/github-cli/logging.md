
| Event | Level | Message shape |
|-------|-------|---------------|
| Every `gh` call, including one that found no `gh` | info | `` `gh <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

Recorded through the git command log, so the line and the in-memory entry follow its rules: no standard output anywhere, standard error only in the in-memory ring and only for a non-zero exit. The title and body of `pr create` are redacted (**text-redacted**).

