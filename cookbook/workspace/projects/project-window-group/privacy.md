
- **Data collected**: Repository ids and a selection; the filter text a user
  types is held in memory.
- **Storage**: `state` is what the owner persists (`UserSettings.projectWindows`);
  the filter text is deliberately never stored.
- **Transmission**: None through this code.
- **Retention**: Until the owner removes the window state; this type applies no
  expiry.

