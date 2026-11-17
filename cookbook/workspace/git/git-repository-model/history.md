
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-11-16 | Mike Fullerton | `.annotations`: posted when a signature or review batch lands; refresh loads nothing for it. |
| 1.3.0 | 2026-11-15 | Mike Fullerton | Conflicts: `conflicts` reloaded with the working copy; `writeResolution` writes a resolved file atomically off the main actor, inside the root, keeping its permissions |
| 1.2.0 | 2026-11-14 | Mike Fullerton | Actions: perform refreshes every kind after any action and rethrows; isPerforming, headBranch, hasCommits; remotes and last commit message; operation state: loaded with the working copy, kept on failure, reported as `.operation` when it changes; the watcher classifies `REVERT_HEAD` and `sequencer` as operation |
| 1.1.0 | 2026-11-14 | Mike Fullerton | Final review: refs, stashes, submodules and worktrees load independently; cancelled loads log at debug; contents pass a size cap; a capped file history is logged; the deferred watcher makes one watcher per latest start |
| 1.0.1 | 2026-11-14 | Mike Fullerton | fileHistory returns the client's entries, each commit with the file's path at that commit |
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
