
- **Data collected**: None of its own: it reads the hub mail mirror and passes label changes to the hub.
- **Storage**: Writes label changes into the mirror the host already keeps. `HubMailLocation` also stores one generated device UUID in `UserDefaults` (key `hub_mail_device_id` unless told otherwise), which the hub files the sync cursor under.
- **Transmission**: Label writes go to the hub's action route through the host's hub client.
- **Retention**: The mirror is kept while a hub identity is signed in and is purged when it signs out (`service-sign-out`); a failed purge is reported, not hidden. The device id persists until the app's defaults are deleted.

