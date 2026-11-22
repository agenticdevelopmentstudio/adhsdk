
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `any ActivityPersistence` or `any WorkTrackingPersistence` | none | The host's database, injected into the recorder and the `WorkTrackingController` |
| derived (host rule) | host-defined | `prunable` accepts every span in `InMemoryActivityStore` | Which closed spans `pruneActivity` may delete |
| `endedBefore` | ISO-8601 UTC string | none | Prune cutoff, supplied by the caller |
| `activeSince` | ISO-8601 UTC string | none | Known-roots cutoff; the controller passes `knownRootsSessionDays` days ago |
| one-second floor | constant | 1 second | Spans shorter than this are deleted on close; not configurable |

No environment variables or settings keys are read by this contract.

