
- **Data collected**: The fields `windowTitle`, `workingPath`, `repoRoot`, `branch` and `appName` describe what the user is working on, and `windowTitle` may include document or project names.
- **Storage**: The type does not store itself; the persistence layer (`ActivityPersistence`) and in-memory store own storage.
- **Transmission**: The type crosses the process boundary as part of `WorkTrackingStatus` through the work-tracking XPC protocol; it does no networking.
- **Retention**: Not set by this type; retention is configured outside it (`retentionDays` in `WorkTrackingModels`).

