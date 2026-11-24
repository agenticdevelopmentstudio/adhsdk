
The panes are not gated by a flag in this package. Whether a workspace sees Jobs is decided by the
`jobs` feature in the backend's feature catalog, which requires `ai-settings`, and by the
`jobs_feature` product switch. While the switch is off every `/jobs` route answers 404, which the
panes read as the feature being unavailable.

