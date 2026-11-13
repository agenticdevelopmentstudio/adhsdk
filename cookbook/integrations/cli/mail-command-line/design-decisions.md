
**Decision**: The command line never contacts a service directly; it takes an injected `MailClient` and two output closures instead of reading process streams.
**Rationale**: This keeps parsing and formatting testable with a scripted client and lets one parser serve any host that spells the command differently (`program`), such as `{{app_name_lower}} mail`.
**Approved**: pending

**Decision**: A blank `--query` is a usage error rather than being forwarded.
**Rationale**: The source comment states that an empty query would quietly list the synced mail instead of searching, so the parser refuses it to avoid a misleading result.
**Approved**: pending

**Decision**: `--limit` is validated only as a positive integer; the upper bound of 500 is applied by clamping inside `MailMessageFilter`.
**Rationale**: The range lives with the filter type, so the parser stays independent of it and an oversized limit is made safe rather than refused.
**Approved**: pending

**Decision**: When no `--from` is given, `move` sends `from` as nil, not an empty list.
**Rationale**: The usage text documents that with no `--from` the service removes INBOX (and nothing when `--to` is INBOX); nil lets the service tell "default" from "remove nothing".
**Approved**: pending

**Decision**: Dates are normalized to UTC strings before the filter is built; date-only `--until` ends at 23:59:59.999Z.
**Rationale**: The `MailDateBound` comment says the store compares UTC strings lexically, so every bound must be in one canonical shape and a day-long range must include its whole last day.
**Approved**: pending

**Decision**: The help check runs before parsing and accepts `-h` or `--help` in any position.
**Rationale**: A user can append `--help` to any partially typed command (`mail list --help`) and get usage with status 0; the cost is that a value equal to `-h` is also read as a help request.
**Approved**: pending

**Decision**: The message body falls back from `bodyText` to converted `bodyHtml` to `snippet`, and HTML that converts to nothing falls through to the snippet.
**Rationale**: The source comment explains the service fills `bodyText` itself, and converting here as well keeps HTML-only mail readable from an older service; an image-only promotion converts to an empty string and would otherwise print a blank body.
**Approved**: pending

**Decision**: A filter the service ignores (`--any-label`, `--query`) fails the command instead of printing an unfiltered page.
**Rationale**: `MailClient` throws when `appliedAnyLabels` or `appliedQuery` is false, and the command line reports it as status 1, so a stale service never shows the wrong mail as if it were filtered.
**Approved**: pending

**Decision**: Rejecting `--any-label` together with `--query` is left to the service; the command line only documents it in the usage text.
**Rationale**: The service's `list` handler refuses the combination, so the command line forwards the filter unchanged and one place owns the rule.
**Approved**: pending

