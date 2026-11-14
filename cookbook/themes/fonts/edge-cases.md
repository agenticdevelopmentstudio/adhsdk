
- **Empty selection**: When no face is flagged, the list MUST be empty; the module raises nothing. The adh consumer test asserts a non-empty list, which is where that case is caught.
- **Missing manifest or missing field**: The manifest is a static JSON import, so a missing file fails at build or bundle time. A face lacking `file` would produce the text `undefined` in its href, since nothing checks it; the generator is the guard.
- **Stale paths**: The `publicPath` embeds a revision. If the bytes are not copied to that path (the app did not call `materializeThemeFonts`), the preload and the inlined `@font-face` both return 404 while the page falls back to the metric-matched fallback; the source's doc comment states that nothing downstream notices.
- **Non-boolean `preload`**: The filter uses truthiness, so any truthy value selects the face.
- **Boundary values**: Not applicable; the module takes no input and has no numeric limits.
- **Concurrent access**: Not applicable; the value is built once at module load, never mutated, and JavaScript module evaluation is single-threaded.
- **Offline or network failure**: Not applicable to this module, which performs no I/O; a failed fetch of a listed href is the browser's concern, and the page keeps the fallback face.
- **Cancellation and timeouts**: Not applicable; nothing here is asynchronous.

