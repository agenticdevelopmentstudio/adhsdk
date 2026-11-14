
- **No selection (the "All" frontier):** when a level has no selection, its pane shows
  that level's landing (the select nudge, or the host's own under `overview: false`)
  and the deeper rails are not rendered; the breadcrumb ends at the last selected crumb.
- **Stale/deleted segment in the URL:** an unknown id falls back to that level's landing
  rather than a phantom-scoped pane: the host checks the id against the level's items (as the hub's `ResourceTab` does with its `knownId` check) and passes `selectedId: null` when none match.
- **Heterogeneous leaves:** a leaf may itself be a master/detail (e.g. Applications =
  list + editor); the leaf's own action bar renders **in its leaf-most details panel**,
  not in the top chrome.
- **Persistent outer rails:** on workspace routes the workspaces + features rails are
  rendered by the shell layout (persist across feature navigation); a feature view must
  not re-render them.
- **Window too small for any rail:** all rails auto-undisclose to icon strips before the
  detail pane drops below its min width; once every list is an icon strip, the leftmost strips slide
  off-screen one whole list at a time (#requirements/hide-off-screen-progressively); only when every
  collapsible list is off-screen and the detail is at its minimum does the frame switch to **narrow**
  mode (one full-width pane at a time, #requirements/exhaust-wide-before-narrow) rather than crushing
  or scrolling the detail.
- **A revealed branch wider than the container:** the branch opens in place and is clipped
  by the frame's right edge — the hovered list and the children that fit are shown. It is a
  transient hover, not a layout: the fit rules own the persistent layout, and the branch
  closes back into it.
- **Single level:** with one topic list the view is just `[rail] | [detail]` — still a
  valid (degenerate) hierarchy with the same chrome.

