
- The daemon is not running: the daemon source lists nothing and never
  becomes authoritative (**daemon-not-running**); the popup lists the leading
  choices, the stored selection is left unchanged, and with no configuration
  selected the model row is disabled and reads "Choose a Model".
- A configuration whose template no longer resolves: it stays listed under
  its name; its model row shows the stored id or "Choose a Model". With the
  daemon source its chooser lists only the stored model; with the local
  source there is no chooser context and the model row is disabled.
- Two controls bound to the same settings (two windows open): each updates
  from the other's writes (**external-change-refresh**).
- No leading choices, no configurations and no stored selection: the popup
  is empty and the model row disabled. With a stored selection the popup is
  still empty and the setting is left unchanged (**stale-selection-kept**).
- A model setting shared by several providers (summaries and oversight): a
  provider change still writes `""` to it, which is the new provider's
  default.

