
- **Null and empty input — sections**: `data`, `error` and `updatedAt` are each typed nullable, so a section can be fully empty.
- **Null and empty input — views**: the view fields typed nullable may be `null`; lists such as `sites` may be empty, and `siteReports` may be an empty object.
- **Malformed input — versions**: the types say `views` is required; tolerating a backend that sends none is done by the components (`viewsMissing`), not by this module.
- **Concurrent access**: not applicable — the module holds only immutable constants and types.
- **Error states**: not applicable — the module holds no behavior; the section `error` field is only a typed string or `null`.
- **Offline and cancellation**: not applicable — the module performs no I/O.
- **Drift**: if the server adds or renames a field, the parity check fails until the web copy is updated; a field the web copy lacks is not visible to the pages.

