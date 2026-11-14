
### Refs sidebar

The topic list's appearance throughout. Icons (SF Symbols): working copy `square.and.pencil`, local branch `arrow.triangle.branch`, remote branch `network`, tag `tag`, stash `tray`, submodule `shippingbox`, worktree `folder`. The ahead/behind badge is the topic list's trailing badge; the checked-out branch uses its emphasized (bold) label.

### History list

A `ThemedTableView` in a `ThemedScrollView`, with a themed header and themed row selection. The subject is body text in the primary colour; the author name and the date are body text in the secondary colour; the sha is the code font in the secondary colour. Ref badges are the toolkit's `Badge`: local branch filled `accent`, remote branch outlined `accent`, tag outlined `warning`, repainted on a theme change. The avatar is 18 points and shows initials only.

### Changed-files list

A headerless, single-column `ThemedTableView` in a `ThemedScrollView`, with themed row selection. Each row: the status letter in the code font, coloured by status (modified orange, added and untracked green, deleted red, renamed and copied blue, conflicted purple, ignored grey); the file type's SF Symbol in the secondary colour; the title as body text in the primary colour, truncated in the middle.

### Commit detail

The header scrolls on its own above the changed-files list and takes at most half the detail's height. The subject is heading text, the body body text, both selectable; the names primary body text, emails and dates secondary; the sha the code font in the secondary colour, followed by a borderless `doc.on.doc` copy button. Parent links are borderless buttons titled in the accent colour and code font. The avatars are 28 points and show initials only.

### Working copy

Two panes in a horizontal-divider `ThemedSplitView`, staged above unstaged, each a heading-weight caption header over its changed-files list.

### Diff

A controls row (the native segmented control, two checkboxes and two push buttons, small control size) above the toolkit's line viewer in the theme's code font. Inline: one viewer. Side by side: two viewers in a vertical-divider `ThemedSplitView`, split evenly. Rows use the viewer's backgrounds: added `.success` and removed `.danger` at 0.18 alpha, emphasis runs at 0.40, headers `.surface`, fillers hatched `.surface`.

### Blame

One line viewer; its three gutter columns are 8, the widest initials (at least 2) and 10 characters wide.

### File history

A vertical-divider `ThemedSplitView`: the commit list (a headerless single-column `ThemedTableView`, rows of a primary-colour subject over a secondary-colour detail line) on the left, the diff on the right.

