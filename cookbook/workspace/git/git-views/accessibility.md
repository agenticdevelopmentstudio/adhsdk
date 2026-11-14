
### Refs sidebar

The sidebar's root view carries the identifier `git.sidebar`. Rows are the topic list's, so each row's label carries `topic-list.item.<slug of title>` and answers an accessibility press by selecting the row; a badge carries `topic-list.item.<slug>.badge`. Because the identifier comes from the title, a branch name shared by `Branches` and a `Remotes · <remote>` section (`main`) yields the same identifier in each; address one with `dev.py ax --nth`.

### History list

The root view carries `git.history`, the table `git.history.table`. Cells carry `git.history.subject`, `git.history.author`, `git.history.date` and `git.history.sha`; the graph cell keeps its own `commitGraph.cell` and the avatar `avatar`. Badges carry `git.history.badge.local`, `git.history.badge.remote` or `git.history.badge.tag`. Rows are table rows, so `dev.py ax --nth` picks one.

