
This component makes no logging call of its own. The one error it
swallows (refresh's failure path) is recorded by a different component,
the git command log kept by the injected git client's unconditional
recording (see [adhsdk.ingredient.workspace.files.git-status-provider](cookbook:9a4aa2a8-c01b-4cec-b789-6c89c100d8d3)'s
sibling git client entry), not logged a second time here.

| Event | Level | Message |
|-------|-------|---------|
| (none) | — | This component emits no log messages. |

