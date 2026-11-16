
### Refs sidebar

The sidebar's root view carries the identifier `git.sidebar`. Rows are the topic list's, so each row's label carries `topic-list.item.<slug of title>` and answers an accessibility press by selecting the row; a badge carries `topic-list.item.<slug>.badge`. Because the identifier comes from the title, a branch name shared by `Branches` and a `Remotes · <remote>` section (`main`) yields the same identifier in each; address one with `dev.py ax --nth`. Context menu items carry `git.sidebar.menu.<name>`: `checkout`, `newBranch`, `rename`, `delete`, `push`, `pull`, `fetch`, `apply`, `pop` and `drop`, a tag's `tag.push` and `tag.delete`, and for worktrees and submodules `newWorktree`, `open`, `removeWorktree`, `updateSubmodule` and `updateAllSubmodules`.

### History list

The root view carries `git.history`, its scroll view `git.history.scroll`, the table `git.history.table`, each row view `git.history.row`. Cells carry `git.history.subject`, `git.history.author`, `git.history.date` and `git.history.sha`; the graph cell keeps its own `commitGraph.cell` and the avatar `avatar`. Badges carry `git.history.badge.local`, `git.history.badge.remote` or `git.history.badge.tag`; the signing badge carries `git.history.signature` and the review badge `git.history.review`, each an image whose accessibility label is its tooltip. Rows are table rows, so `dev.py ax --nth` picks one. Context menu items carry `git.history.menu.<name>`: `checkout`, `newBranch`, `newTag`, `cherryPick`, `revert`, `reset` (the submenu's item), `resetSoft`, `resetMixed`, `resetHard` and `copySha`.

### Changed-files list

The root view carries `git.fileList.<context>` (`commit`, `conflicts`, `staged`, `unstaged`), its scroll view `git.fileList.<context>.scroll` and its table `git.fileList.<context>.table`. Each row view carries `git.fileList.row`, each cell `git.fileList.file`, and within it `git.fileList.status`, `git.fileList.icon` and `git.fileList.title`. The status letter's accessibility label is the status's readable, localized name, `GitFileStatus.displayName` (`Modified`, `Added`, …), never its case name.

### Commit detail

The root view carries `git.detail`, the header's scroll view `git.detail.header`; then `git.detail.subject`, `git.detail.body`, `git.detail.author`, `git.detail.committer` (each row; its avatar keeps `avatar`), `git.detail.sha`, `git.detail.copySha` (accessibility label `Copy SHA`) and `git.detail.parent` for each parent link (use `dev.py ax --nth` for a merge). The review section carries `git.commit.review` (accessibility label `Review: <state>`), its caption `git.commit.review.caption`, the row `git.commit.review.stateRow` holding `git.commit.review.symbol` and `git.commit.review.state`, the text `git.commit.review.summary` and the button `git.commit.review.open`. Its list is `git.fileList.commit`.

### Working copy

The root view carries `git.workingCopy`, its split `git.workingCopy.split` and the panes `git.workingCopy.conflictsPane`, `git.workingCopy.stagedPane` and `git.workingCopy.unstagedPane`; the headers `git.workingCopy.conflictsHeader`, `git.workingCopy.stagedHeader` and `git.workingCopy.unstagedHeader`, and the lists `git.fileList.conflicts`, `git.fileList.staged` and `git.fileList.unstaged`; the header buttons `git.workingCopy.stageAll` and `git.workingCopy.unstageAll`; the menu items `git.workingCopy.menu.stage`, `git.workingCopy.menu.unstage`, `git.workingCopy.menu.discard` and `git.workingCopy.menu.discardAll`, and on a conflict row `git.workingCopy.menu.openMerge`, `git.workingCopy.menu.resolveOurs`, `git.workingCopy.menu.resolveTheirs` and `git.workingCopy.menu.markResolved`. The commit box carries `git.commitBox`, its header `git.commitBox.header`, the message `git.commitBox.message`, the checkbox `git.commitBox.amend` and the button `git.commitBox.commit`.

### Diff

The root view carries `git.diff`; the controls `git.diff.controls`, `git.diff.layout`, `git.diff.ignoreWhitespace`, `git.diff.wordHighlight`, `git.diff.blame` and `git.diff.history`; the inline viewer `git.diff.inline` and the side-by-side viewers `git.diff.left` and `git.diff.right` (in `git.diff.split`), each with the viewer's own `.text` and `.gutter`; the error label `git.diff.error`.

### Blame

The root view carries `git.blame`, its viewer `git.blame.lines` (with `.text` and `.gutter`) and the error label `git.blame.error`.

### File history

The root view carries `git.fileHistory`, the split `git.fileHistory.split`, the list's scroll view `git.fileHistory.scroll`, its table `git.fileHistory.table`, each row view `git.fileHistory.row`, each cell `git.fileHistory.commit` with `git.fileHistory.subject` and `git.fileHistory.details`, the error label `git.fileHistory.error`, and the diff's own `git.diff`.

### Pull requests

The section header carries `git.sidebar.pullRequests` (`TopicListSection.accessibilityIdentifier`), rows `git.sidebar.pullRequests.<number>` and their menu items `git.sidebar.pullRequests.menu.<checkout|open|copyURL|create>`. The detail's root view carries `git.pullRequest`, its fields `git.pullRequest.<title|number|state|author|branches|review|checks|updated>` in the grid `git.pullRequest.fields`, and its buttons `git.pullRequest.open` and `git.pullRequest.checkout` in `git.pullRequest.buttons`. The form's window carries `git.pullRequest.form`, its controls `git.pullRequest.form.<title|body|bodyScroll|base|draft>` in `git.pullRequest.form.fields`.

