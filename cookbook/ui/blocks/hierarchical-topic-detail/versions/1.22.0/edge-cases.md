
- **No selection (the "All" frontier):** when a level has no selection, its pane shows
  that level's landing (the select nudge, or the host's own under `overview: false`)
  and the deeper rails are not rendered; the breadcrumb ends at the last selected crumb.
- **Stale/deleted segment in the URL:** an unknown id falls back to that level's landing
  rather than a phantom-scoped pane (mirrors the FTD `knownId` rule).
- **Heterogeneous leaves:** a leaf may itself be a master/detail (e.g. Applications =
  list + editor); the leaf's own action bar renders **in its leaf-most details panel**,
  not in the top chrome.
- **Persistent outer rails:** on workspace routes the workspaces + features rails are
  rendered by the shell layout (persist across feature navigation); a feature view must
  not re-render them.
- **Window too small for any rail:** all rails auto-undisclose to icon strips before the
  detail pane drops below its min width; below that the frame switches to **narrow** mode
  (one full-width pane at a time) rather than crushing or scrolling the detail.
- **A revealed branch wider than the container:** the branch opens in place and is clipped
  by the frame's right edge — the hovered list and the children that fit are shown. It is a
  transient hover, not a layout: the fit rules own the persistent layout, and the branch
  closes back into it.
- **Single level:** with one topic list the view is just `[rail] | [detail]` — still a
  valid (degenerate) hierarchy with the same chrome.

