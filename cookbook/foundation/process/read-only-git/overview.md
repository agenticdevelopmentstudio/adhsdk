
Read Only Git runs a `git` command whose only purpose is to read repository state, for a status line or a hook helper. It is a case-less namespace (`ReadOnlyGit`) in the core framework, and the one spawn point for `git` on the hook and status-line path (the general git client in `Core/Git/` is the door for everything else).

Three things make it safe to call constantly:

1. It sets `GIT_OPTIONAL_LOCKS=0`, so `git status` and friends never take `index.lock` to refresh the stat cache. A status line re-renders all the time, and a background `git` holding the index lock would race the user's own commit, rebase or add in the same worktree ("Unable to create '…/index.lock'").
2. It gives each call a 5-second limit. A status line re-renders constantly, so a `git` that has not answered in time is dropped rather than waited on.
3. It repairs `PATH`, because a status line launched from the GUI inherits a minimal path (`/usr/bin:/bin:/usr/sbin:/sbin`, no Homebrew).

It offers two forms: `git(_:)`, which trims the output (the default, for any displayed value), and `rawGit(_:)`, which returns the bytes untouched for output where leading or trailing whitespace carries meaning (`git status --porcelain`). Any failure (a non-zero exit, a hang past the limit, a spawn error, output that is not UTF-8) collapses to the empty string. It runs the process through `CommandRunner.runToCompletion`, described by the command-runner recipe ([adhsdk.ingredient.foundation.processes.command-runner](cookbook:705082e9-8fad-4c20-95a3-4cf843cc6b97)).

