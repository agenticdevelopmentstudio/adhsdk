
Not applicable — this is a networking transport-selection component, not a
visual component. Its one runtime state machine (uncached / cached-direct /
cached-daemon, driven by `TransportResolver.cachedKind`) is specified under
Behavioral Requirements ("TransportResolver — decision and caching") rather
than as a visual-state table.

