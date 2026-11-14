
- **Null and empty inputs** (MUST): an empty `problems` list, no services, no checks, no groups and null optional fields give empty sections and no findings; `firstLine` returns null for empty text; a missing `detail` leaves the field off the finding.
- **Boundary values** (MUST): uptime exactly 99.5 is not a finding; a runtime 5xx with count 4 is minor and with count 5 is major; a site at exactly 5% failure is troubled; exactly 15 active issues give no overflow finding and 16 do.
- **Zero requests** (MUST): a site with no requests is troubled when its errors plus failures are above 0, and not otherwise.
- **Hidden-group severity** (MUST): when the runtime report's own cap already dropped groups (`total` above the group count), the overflow severity is judged only from the groups present past `RUNTIME_GROUP_CAP`, since the dropped ones sort after every listed one; with none present it is minor.
- **Site cap** (MUST): only the first `SITE_ROW_CAP` rows by trouble are considered for findings, so a troubled site below that cut-off raises no finding, though it stays in the section.
- **Error states** (MUST): a failed source never throws; it becomes a failed coverage entry and a major finding, and the other digests are unaffected.
- **Missing deploys read** (MUST): with the deploys read failed, the monitor digest receives no provider list and keeps every platform-health problem.
- **Missing monitor read** (MUST): with the monitor read failed, the deploys digest lists no failing deploys and a provider finding is minor.
- **Time zone and clock** (MUST): the module reads no clock; `generatedAt` is the supplied `now`, and the only other date it renders is the failing runtime read's `atMs` as an ISO string.
- **Concurrent access**: not applicable; every function is synchronous and pure over its arguments, so there is nothing to interleave.
- **Offline or disconnected state**: not applicable; the module does no I/O. A source that was unreachable arrives as a failed read, which is covered by the failed-source requirement.
- **Duplicate names** (MUST): two open issues with the same name get their targets as keys, so a key never matches two issues.

