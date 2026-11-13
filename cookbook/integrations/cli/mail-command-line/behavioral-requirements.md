
### Entry points and exit statuses

- **usage-text**: `usage(program:)` MUST return the usage text with every occurrence of the command name replaced by `program`, defaulting to `mail` (a host passes `temporal mail`).
- **usage-lists-commands**: The usage text MUST list the commands `accounts`, `labels`, `list`, `get`, `thread`, `label add`, `label remove` and `move` with their options, and the `[--json]` flag.
- **usage-documents-exit-statuses**: The usage text MUST state the exit statuses: 0 success, 1 failure, `notFoundStatus` (3) a message id matches nothing, 64 usage error.
- **usage-documents-label-combination**: The usage text MUST state that `list` requires a message to carry every `--label` (AND) and, if any `--any-label` is given, at least one of them (OR), and that the two combine.
- **not-found-status**: `notFoundStatus` MUST be the `Int32` value 3.
- **run-signature**: `run` MUST be `async`, take the argument list (without the leading `mail`), a `program` name defaulting to `mail`, a `MailClient`, and two `@Sendable (String) -> Void` closures, and return an `Int32` exit status.
- **help-request**: `run` MUST write the usage text to `stdout`, write nothing to `stderr`, and return 0 when the first argument is `help` or when any argument equals `--help` or `-h`.
- **help-before-parse**: `run` MUST check for a help request before parsing, so help is honored even when the remaining arguments would be a usage error, and it MUST NOT call the client.
- **usage-error-status**: When the arguments cannot be parsed, `run` MUST write the usage text to `stderr`, write nothing to `stdout`, make no client call and return 64.
- **success-status**: When the command runs without throwing, `run` MUST return 0.
- **not-found-handling**: When the client throws `MailClientError.notFound`, `run` MUST write `Error: ` followed by its message to `stderr`, write nothing to `stdout` and return `notFoundStatus`.
- **failure-handling**: When the client or the JSON encoder throws any other error, `run` MUST write `Error: ` followed by the error's `localizedDescription` to `stderr`, write nothing to `stdout` and return 1.
- **skip-empty-output**: `run` MUST NOT call `stdout` when the formatted output is the empty string.
- **single-write**: `run` MUST write a successful result to `stdout` as one string, with lines joined by a newline and no trailing newline.

### Argument parsing (shared)

- **command-selection**: The first argument MUST select the command; an empty argument list or a first argument other than `accounts`, `labels`, `get`, `list`, `thread`, `label` or `move` MUST be a usage error.
- **json-flag**: The `--json` option MUST be accepted anywhere in the arguments of every command and MUST switch the output to JSON.
- **unknown-option**: Any argument beginning with `--` that is neither `--json` nor an option the command declares MUST be a usage error.
- **value-required**: A value-taking option appearing as the last argument MUST be a usage error.
- **value-consumption**: A value-taking option MUST consume the next argument as its value whatever that argument looks like, so `--limit -3` reaches the limit check as the value `-3`.
- **single-dash-positional**: An argument that does not begin with `--` and is not a consumed value MUST be a positional, including a single-dash token other than `-h`.
- **positional-count-fixed**: `accounts` MUST take exactly 0 positionals, `labels` exactly 1 (account), `get` exactly 2 (account, id), `thread` exactly 2 (account, id) and `list` exactly 1 (account); any other count MUST be a usage error.
- **repeated-option-last-wins**: When `--since`, `--until`, `--limit`, `--cursor` or `--query` is given more than once, the last occurrence MUST be used.

### accounts and labels

- **accounts-call**: `accounts` MUST call `client.accounts()`.
- **accounts-text**: In text mode each account MUST print as one line `<email>  <status raw value>  <lastSyncAt or "never">`, separated by two spaces.
- **labels-call**: `labels <account>` MUST call `client.labels(account:)`.
- **labels-text**: In text mode each label MUST print as one line `<name>  <id>  <type>`, separated by two spaces.

### list

- **list-call**: `list <account>` MUST build a `MailMessageFilter` for the account and call `client.messages` with it.
- **list-label-options**: Each `--label` MUST be appended to the filter's `labels` and each `--any-label` to its `anyLabels`, in the order given.
- **list-date-bounds**: `--since` MUST be normalized as the start edge and `--until` as the end edge through `MailDateBound.normalize`: `YYYY-MM-DD` becomes `T00:00:00.000Z` for `--since` and `T23:59:59.999Z` for `--until`, and an ISO-8601 timestamp is converted to UTC with millisecond precision.
- **list-date-invalid**: A `--since` or `--until` value that `MailDateBound.normalize` rejects (not a date or timestamp, or a nonexistent date such as 2026-02-30) MUST be a usage error.
- **list-limit-valid**: `--limit` MUST be a base-10 integer greater than 0, otherwise a usage error.
- **list-limit-clamp**: A valid `--limit` MUST be assigned to the filter, whose `limit` property clamps it into 1 through 500; with no `--limit` the filter keeps its default of 50.
- **list-cursor**: `--cursor` MUST be passed through to the filter's `cursor` unmodified.
- **list-bodies**: `--bodies` MUST set the filter's `includeBodies` to true; without it `includeBodies` MUST stay false.
- **list-query-valid**: `--query` MUST be passed to the filter's `query` unmodified.
- **list-query-blank**: A `--query` value that is empty or only whitespace and newlines MUST be a usage error, because an empty query would quietly list synced mail instead of searching.
- **list-any-label-with-query**: The command line MUST NOT itself reject `--any-label` combined with `--query`; it forwards both and the mail service refuses the combination.
- **list-text**: In text mode each message MUST print as `<date>  <id>  <from>  <subject>  [<label names joined by ", ">]`, and when the page has a `nextCursor` a final line `next cursor: <cursor>` MUST follow the message lines.
- **list-json**: In JSON mode the whole `MailMessagePage` MUST be encoded, including `nextCursor`.
- **list-ignored-filter**: When the client throws because the service ignored `--any-label` or `--query` (`MailClient` rejects a page whose `appliedAnyLabels` or `appliedQuery` is false), `run` MUST treat it as an ordinary failure: status 1, the message on `stderr`, nothing on `stdout`.

### get and thread

- **get-call**: `get <account> <id>` MUST call `client.message(account:id:)`.
- **get-text**: In text mode `get` MUST print the header lines `From:`, `To:` (recipients joined by ", "), `Date:`, `Subject:` and `Labels:` (label names joined by ", "), a blank line, then the body.
- **body-fallback**: The body MUST be `bodyText` when present; otherwise the plain text converted from `bodyHtml` by `HTMLText.plainText(fromHTML:)` when that is non-empty; otherwise the `snippet`.
- **html-without-text**: HTML that converts to the empty string (an image-only message) MUST fall through to the snippet.
- **thread-call**: `thread <account> <id> [--bodies]` MUST call `client.thread(account:id:includeBodies:)`, where `id` is a thread id or the id of any message in the thread.
- **thread-text-summary**: Without `--bodies`, text mode MUST print a header `thread <thread id>  <n> message` (`messages` when n is not 1) followed by one message line per message in the order the client returned them.
- **thread-sent-marker**: A message whose `labels` contain `SENT` MUST be marked `(you)`: appended after two spaces on its message line without `--bodies`, and as a `(you)` line before its detail block with `--bodies`.
- **thread-text-bodies**: With `--bodies`, text mode MUST print the header and then each message's `get` detail block, with the blocks separated by a blank line, a line of four hyphens and a blank line.
- **thread-json**: In JSON mode the whole `MailThread` MUST be encoded.
- **thread-options**: `thread` MUST accept `--bodies` and `--json` only; any other `--` option MUST be a usage error.

### label add, label remove and move

- **label-verb**: `label` MUST require its first argument to be `add` or `remove`, otherwise a usage error.
- **label-arity**: `label add` and `label remove` MUST require at least three positionals after the verb (account, label, and one or more ids), otherwise a usage error.
- **label-call**: `label add` MUST call `client.modifyLabels` with the label as the only `add` entry and no `remove`; `label remove` MUST do the reverse; both MUST pass all ids in the order given.
- **label-options**: `label add` and `label remove` MUST accept only `--json` as an option; any other `--` option MUST be a usage error.
- **label-text**: In text mode `label add` and `label remove` MUST print one message line per returned message.
- **move-arity**: `move` MUST require at least two positionals (account and one or more ids) and exactly one `--to`, otherwise a usage error; zero or two `--to` are both usage errors.
- **move-from**: Each `--from` MUST be collected in order; with no `--from` the `from` argument MUST be nil (not an empty list) so the service applies its default of removing INBOX.
- **move-call**: `move` MUST call `client.moveMessages` with the account, the ids in the order given, the single `--to` value as `destination` and the collected `from`.
- **move-position-free**: `--to`, `--from` and ids MAY appear in any order after the account.
- **move-text**: In text mode `move` MUST print one line per `MailMoveResult`: the message line, two spaces, then each added label as `+<name>` followed by each removed label as `-<name>`, separated by single spaces, or `(no change)` when both are empty.
- **move-json**: In JSON mode the array of `MailMoveResult` values MUST be encoded.

### Output encoding and concurrency

- **json-encoding**: JSON output MUST be produced by `MailJSON.encode`, pretty printed with sorted keys, as UTF-8 text; a failure to produce UTF-8 text is an encoding error reported as a failure (status 1).
- **one-client-call**: Each successful invocation MUST make exactly one call on the client.
- **no-shared-state**: `run` MUST hold no state between calls: parsing builds local values, so concurrent invocations with different clients do not interact.

