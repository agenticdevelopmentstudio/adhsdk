
**Decision**: Judge the Errors card's figures once on the server, in one pure function.
**Rationale**: The doc comment says "so no client re-derives them"; the test header notes status-web
used to work them out from the raw rows. One copy removes drift between clients.
**Approved**: pending

**Decision**: A row with no `active` verdict counts as backlog.
**Rationale**: The doc comment: "never as an incident and never as clear". An unjudged row must not
raise an alarm or look resolved; the summary is only meant to be attached where every row was judged.
**Approved**: pending

**Decision**: Sort the active rows by `count` descending instead of keeping GlitchTip's order.
**Rationale**: GlitchTip sends issues in last-seen order, not by volume; the list must match its
`{count}×` labels. The cap of five (`ERRORS_TOP_COUNT`) keeps the card short.
**Approved**: pending

**Decision**: `events` totals every row including backlog, and guards falsy `count` there but not in the sort.
**Rationale**: The card reports "how many events all of them carry". The unguarded sort is a small
inconsistency in the source, recorded here so ports do not silently diverge; `ErrorDTO.count` is typed `number`.
**Approved**: pending

