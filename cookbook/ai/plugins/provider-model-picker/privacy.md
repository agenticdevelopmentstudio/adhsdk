
- **Data collected**: None of its own. The local source reads a
  configuration's API key only to build the chooser context.
- **Storage**: The provider selection and the model setting, both
  caller-supplied, non-secret settings.
- **Transmission**: The daemon source asks the local daemon over loopback for
  its provider list; nothing leaves the machine except what the chooser
  fetches (see the model picker).
- **Retention**: The settings persist until changed; the control keeps no
  copy.
- **Security-violation handling**: Not applicable: the control has no
  detection surface.

