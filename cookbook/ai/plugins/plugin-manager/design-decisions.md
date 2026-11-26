
**Decision**: Plugin compatibility is an integer ABI stamp, `AIPluginKitABIVersion`, written into each plugin's built Info.plist at build time from the `AIPluginABI.version` constant in the plugin kit's source, and compared for equality at discovery and again before loading.
**Rationale**: A plugin links the host's single copy of the plugin kit (`shared-framework-image`), and that framework is not built for library evolution, so a plugin built against other type layouts can crash the host as soon as a type crosses the boundary; the check has to happen before any plugin code is mapped. The Info.plist is readable without loading code, unlike the binary, and is separate from the descriptor, whose schema version covers the descriptor's shape rather than the code's. One constant in the kit's source is the single source of truth: the build's stamp script reads it, so no build setting has to be kept in step across projects. The constant is bumped by hand on any change to a type a plugin shares with the host.
**Approved**: pending

**Decision**: Loading a plugin caches one instance per identifier for the manager's lifetime instead of creating a fresh instance per call, even though the plugin protocol's own doc comment says "Instances are cheap and may be created per request."
**Rationale**: Caching avoids repeating the bundle-load/principal-class resolution on every request and keeps the loaded-bundles bookkeeping simple (one bundle reference per identifier); since macOS never truly unloads a loaded bundle's binary anyway (per `unload-retains-bundle`), there is no memory cost to keeping one instance alive alongside it. (Apple platform implementation.)
**Approved**: pending

**Decision**: A duplicate identifier discovered from a later search path is dropped silently, with the earlier one always winning.
**Rationale**: The source's own comment on the app-name initializer states the search-path order is deliberate — "the bundle's own copy wins, then the hand-filled dotfolder, then what an installer wrote" — so first-discovered-wins is how that stated precedence is implemented, not an oversight.
**Approved**: pending

**Decision**: Unloading a plugin removes the cached instance but leaves its bundle cached forever.
**Rationale**: The source's own comment states "the bundle remains loaded in memory (macOS does not support unloading bundles)" — since the OS will not release the mapped binary regardless, removing the bundle reference would only lose the manager's own bookkeeping for no memory benefit. (Apple platform implementation.)
**Approved**: pending

**Decision**: A search-path entry that cannot be enumerated is skipped silently.
**Rationale**: Unlike every other skip branch in discovery, no warning is logged and nothing is surfaced to the caller; closing the gap takes whoever owns the manager's callers deciding whether an enumeration failure should log, be surfaced through a return value, or stay silent.
**Approved**: pending

**Decision**: An empty app name is not validated.
**Rationale**: An empty app name widens the search to the shared plugins location, a risk documented only in the helper the manager calls and not enforced at this call site; closing the gap takes confirming whether the app name can ever be empty before app metadata is configured, and if so rejecting it (an assertion) or defaulting it.
**Approved**: pending

