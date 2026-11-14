
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-window-001 | window-key-canonical, one-window-per-key | A temporary repository with a subdirectory `sub`; open `sub`, then the root, both with `activates` false | The same controller both times; its window id is `git:` + the canonical root path; the remembered list holds that one path. |
| git-window-002 | non-repository-refused | A temporary directory that is not a repository; open it | nil; the remembered list is unchanged. |
| git-window-003 | commands | Branch management for a checkout, with a registry that holds `git.action.openWindowForPath` | Its commands include `branch.action.openGitWindow.<checkout id>` titled `Open in Git Window`; running it executes the open-for-path command with the checkout's directory path. |
| git-window-004 | commands | The same, with a registry that does not hold it | No such command. |
