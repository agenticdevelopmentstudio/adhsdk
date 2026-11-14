
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
