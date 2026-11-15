
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-window-001 | window-key-canonical, one-window-per-key | A temporary repository with a subdirectory `sub`; open `sub`, then the root, both with `activates` false | The same controller both times; its window id is `git:` + the canonical root path; the remembered list holds that one path. |
| git-window-002 | non-repository-refused | A temporary directory that is not a repository; open it | nil; the remembered list is unchanged. |
| git-window-003 | commands | Branch management for a checkout, with a registry that holds `git.action.openWindowForPath` | Its commands include `branch.action.openGitWindow.<checkout id>` titled `Open in Git Window`; running it executes the open-for-path command with the checkout's directory path. |
| git-window-004 | commands | The same, with a registry that does not hold it | No such command. |
| git-window-005 | refresh-reapplies-selection, ref-scrolls-history | `main` selected; a new commit on it, reported as refs and history at once | The history and the commit detail both show the new tip. |
| git-window-006 | refresh-reapplies-selection, refresh-button | `main` selected and an older commit picked in the history; Refresh | The older commit stays selected and shown. |
| git-window-007 | centre-follows-sidebar | A branch selected, then deleted; a refs change | Selection Working Copy, the centre the working copy, the detail empty. |
| git-window-008 | stash-shows-commit | A stash whose id git cannot read is selected | The detail is hidden and the error label `git.window.error` shows git's message. |
| git-window-009 | refresh-reapplies-selection, refresh-button | A working-copy diff of a modified file; the file edited again, then a working-copy change; edited again, then Refresh | The diff shows the new text both times. |
| git-window-010 | refresh-reapplies-selection | A blame of the working file; the file edited, then a working-copy change | The blame shows the new text. |
| git-window-011 | refresh-reapplies-selection | A file history of `a.txt`; a new commit to it, then a history change | One more entry. |
| git-window-012 | search-drives-history | Two commits; a `sha:` search for the older one's prefix, then a message search | The older commit is selected; then the model's query is the parsed message search and only the matching commit is listed. |
| git-window-013 | window-identity | Subtitle `main`; the repository's `.git` moved away; the subtitle read again | The subtitle is still `main`. |
| git-window-014 | file-type-override-validated | Names `C++`, `C#`, `Shell Script`, `bash`, an unknown name, a blank name | `cpp`, `csharp`, `shellscript`, `shellscript` (an alias), nil, nil. |
| git-window-015 | commands | Open Git Window for Path run with no argument, then with a number | No window opens and nothing is remembered. |
| git-window-016 | text-action-enablement | Fields `Name` (required) and `Message` (optional); values `["", "note"]`, `["   ", ""]`, `["v1", ""]`, `["v1"]` | Incomplete, incomplete, complete, incomplete. |
| git-window-017 | one-at-a-time | A clone of a bare remote; `fetch()` twice before the first ends | One busy cycle (`true`, `false`), the spinner shown during it and hidden after; the second request ignored. |
| git-window-018 | discard | A tracked file edited and an untracked file; discard both, confirmed | One confirmation `Discard changes to 2 files?`, destructive, `Discard Changes`; the tracked file restored, the untracked file gone, nothing unstaged. |
| git-window-019 | needs-presenter | No presenter; Discard All and New Branch | Nothing changes. |
| git-window-020 | commit | A staged change; commit `second` | HEAD's subject is `second`; the box is empty. |
| git-window-021 | commit | A commit `The subject\n\nThe body.`; Amend ticked over an empty box, then over `typed` | The box holds the commit's message, then still `typed`. |
| git-window-022 | push-remote | A repository with a commit and no remote, push | `Push failed`: `This repository has no remote.` |
| git-window-023 | push-remote | A detached HEAD, push | `Push failed`: `HEAD is not on a branch.` |
| git-window-024 | push-remote | A clone on a new branch with no upstream, push | The remote has the branch at HEAD; its upstream is `origin/<branch>`. |
| git-window-025 | checkout | A remote branch `origin/feature` with no local branch, checked out; then `origin/main`, tracked by `main` | HEAD is `feature` tracking `origin/feature`; then `main`. |
| git-window-026 | rename-delete | A branch with a commit on no other branch; delete, confirmed twice | Two confirmations, the second `Delete unmerged branch?` and destructive; the branch is gone; no failure. |
| git-window-027 | rename-delete | As 026, the second confirmation declined | The branch remains; no failure. |
| git-window-028 | failure-shown | `f.txt` changed differently on `main` and `side`; cherry-pick `side`'s tip onto `main` | One `Cherry-pick failed` failure; `f.txt` is listed as conflicted. |
| git-window-029 | commit-actions | A merge commit; revert it | No failure; the merged branch's file is gone. |
| git-window-030 | commit-actions | Two commits; a hard reset to the first declined, then a soft reset, then a hard one confirmed | One confirmation `Reset main to <shortID>?` and HEAD unchanged; then HEAD at the first commit with the second's file staged; then nothing staged and the file gone. |
| git-window-031 | sheets-only | A sheet begun on a window that closes before it ends | The sheet is ended once and the question answered as cancelled. |
| git-window-032 | names-validated | New Branch answered `-f` | `Create branch failed`: `A name cannot begin with “-”.`; HEAD unchanged. |
