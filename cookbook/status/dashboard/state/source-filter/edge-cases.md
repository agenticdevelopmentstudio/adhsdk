
- **Empty selection**: toggling off every source MUST give an empty set. For the activity panel, this hides every row that has a known `platform` whenever more than one source exists. Rows whose `platform` is null or missing still show, because the consumer lets them through.
- **Unknown source value**: the source type rules this out at compile time. A value forced in some other way MUST be added to or removed from the in-memory set like any other value, because Source Filter does no runtime check. The set's size can then exceed 8; on the next hydration the unknown value is dropped.
- **Source added to the fixed list later**: new mounts MUST include it in the default. A use that is already mounted does not pick it up until it starts again.
- **Rapid repeated toggles**: each call MUST flip membership once, based on the latest queued state (source-filter-007).
- **Update applied more than once for the same input**: the result MUST be the same as a single application, because the update has no side effects.
- **Reload or remount**: the selection MUST be restored from local storage under the same key after the first render (see source-filter-010). Until then the default all-selected set shows.
- **Stored value that is not recognised**: a stored value that is not valid JSON, or not an array, MUST leave the default selection. Unknown entries inside a stored array MUST be dropped; the known ones are kept.
- **Storage unavailable**: a read or write that throws MUST be swallowed. The default stays on read failure, and the in-memory selection still changes on write failure.
- **Server render**: Source Filter MUST render the default all-selected set on a server-rendering pass. It touches storage only after the first render.
- **Null or empty input, timeouts, cancellation, network loss**: not applicable. The storage key is a required string, and the only I/O is synchronous local storage.

