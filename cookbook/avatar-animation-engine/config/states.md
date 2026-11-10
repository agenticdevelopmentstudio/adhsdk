
Not applicable: the loader has no interactive or lifecycle state of its own
— each call to `load`/`loadConfig` either returns a complete result or
throws; there is no partially-loaded or in-progress state exposed to
callers.

