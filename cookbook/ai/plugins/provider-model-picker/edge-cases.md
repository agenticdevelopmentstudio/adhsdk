
- The daemon is not running: the daemon source lists nothing; the popup keeps
  the leading choices and the stored selection, and the model row shows the
  stored model's id.
- A configuration whose template no longer resolves: it stays listed under
  its name; its model row shows the stored id or "Choose a Model", and its
  chooser lists nothing.
- Two controls bound to the same settings (two windows open): each updates
  from the other's writes (**external-change-refresh**).
- No leading choices and no configurations: the popup is empty and the model
  row disabled.
- A model setting shared by several providers (summaries and oversight): a
  provider change still writes `""` to it, which is the new provider's
  default.

