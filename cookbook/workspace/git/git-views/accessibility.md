
### Refs sidebar

The sidebar's root view carries the identifier `git.sidebar`. Rows are the topic list's, so each row's label carries `topic-list.item.<slug of title>` and answers an accessibility press by selecting the row; a badge carries `topic-list.item.<slug>.badge`. Because the identifier comes from the title, a branch name shared by `Branches` and a `Remotes · <remote>` section (`main`) yields the same identifier in each; address one with `dev.py ax --nth`.

### History list

The root view carries `git.history`, its scroll view `git.history.scroll`, the table `git.history.table`, each row view `git.history.row`. Cells carry `git.history.subject`, `git.history.author`, `git.history.date` and `git.history.sha`; the graph cell keeps its own `commitGraph.cell` and the avatar `avatar`. Badges carry `git.history.badge.local`, `git.history.badge.remote` or `git.history.badge.tag`. Rows are table rows, so `dev.py ax --nth` picks one.

### Changed-files list

The root view carries `git.fileList.<context>` (`commit`, `staged`, `unstaged`), its scroll view `git.fileList.<context>.scroll` and its table `git.fileList.<context>.table`. Each row view carries `git.fileList.row`, each cell `git.fileList.file`, and within it `git.fileList.status`, `git.fileList.icon` and `git.fileList.title`. The status letter's accessibility label is the status's readable, localized name, `GitFileStatus.displayName` (`Modified`, `Added`, …), never its case name.

### Commit detail

The root view carries `git.detail`, the header's scroll view `git.detail.header`; then `git.detail.subject`, `git.detail.body`, `git.detail.author`, `git.detail.committer` (each row; its avatar keeps `avatar`), `git.detail.sha`, `git.detail.copySha` (accessibility label `Copy SHA`) and `git.detail.parent` for each parent link (use `dev.py ax --nth` for a merge). Its list is `git.fileList.commit`.

### Working copy

The root view carries `git.workingCopy`, the headers `git.workingCopy.stagedHeader` and `git.workingCopy.unstagedHeader`, and the lists `git.fileList.staged` and `git.fileList.unstaged`.

### Diff

The root view carries `git.diff`; the controls `git.diff.controls`, `git.diff.layout`, `git.diff.ignoreWhitespace`, `git.diff.wordHighlight`, `git.diff.blame` and `git.diff.history`; the inline viewer `git.diff.inline` and the side-by-side viewers `git.diff.left` and `git.diff.right` (in `git.diff.split`), each with the viewer's own `.text` and `.gutter`; the error label `git.diff.error`.

### Blame

The root view carries `git.blame`, its viewer `git.blame.lines` (with `.text` and `.gutter`) and the error label `git.blame.error`.

### File history

The root view carries `git.fileHistory`, the split `git.fileHistory.split`, the list's scroll view `git.fileHistory.scroll`, its table `git.fileHistory.table`, each row view `git.fileHistory.row`, each cell `git.fileHistory.commit` with `git.fileHistory.subject` and `git.fileHistory.details`, the error label `git.fileHistory.error`, and the diff's own `git.diff`.

