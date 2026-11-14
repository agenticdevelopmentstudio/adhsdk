---
id: be4db0fe-628d-41f8-9fdf-25a6d46844cf
title: "MailCommandLine"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Parses `mail` CLI args, makes one MailClient call, prints text or JSON, returns an exit status."
platforms:
  - swift
  - macos
tags:
  - cli
  - mail
  - argument-parsing
depends-on:
  - fc9671be-170c-436e-9628-892624952191
  - 3d12c073-edc3-44fb-a988-5edec20575e0
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# MailCommandLine

## Overview

`MailCommandLine` is a caseless Swift `enum` that implements the `mail` command line for a host program. A host passes it the arguments after `mail`, a `MailClient` and two output closures. It parses the arguments, makes one call on the client, formats the answer as text (or JSON with `--json`), writes it to the supplied closures and returns a process exit status. It never touches the network, the file system or the process streams itself; the host owns those. It is a headless **logic** component, so Appearance, States and Accessibility are not applicable and the runtime contract lives in Behavioral Requirements.

The commands are `accounts`, `labels`, `list`, `get`, `thread`, `label add`, `label remove` and `move`. The public surface is `usage(program:)`, `run(_:program:client:stdout:stderr:)` and the constant `notFoundStatus`.

## Behavioral Requirements

### Entry points and exit statuses

- **usage-text**: `usage(program:)` MUST return the usage text with every occurrence of the command name replaced by `program`, defaulting to `mail` (a host passes `{{app_name_lower}} mail`).
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
- **json-flag**: The `--json` option MUST be accepted anywhere after the command name (for `label`, after the `add` or `remove` verb) in every command and MUST switch the output to JSON; as the first argument, or as the verb of `label`, it is not a command or verb and is a usage error.
- **unknown-option**: Any argument beginning with `--` that is neither `--json` nor an option the command declares MUST be a usage error.
- **value-required**: A value-taking option appearing as the last argument MUST be a usage error.
- **value-consumption**: A value-taking option MUST consume the next argument as its value whatever that argument looks like, so `--limit -3` reaches the limit check as the value `-3`.
- **single-dash-positional**: An argument that does not begin with `--` and is not a consumed value MUST be a positional, including a single-dash token other than `-h`.
- **positional-count-fixed**: `accounts` MUST take exactly 0 positionals, `labels` exactly 1 (account), `get` exactly 2 (account, id), `thread` exactly 2 (account, id) and `list` exactly 1 (account); any other count MUST be a usage error. `label` and `move` take their counts from **label-arity** and **move-arity**.
- **repeated-option-last-wins**: When `--since`, `--until`, `--limit`, `--cursor` or `--query` is given more than once, the last occurrence MUST be used.

### accounts and labels

- **accounts-call**: `accounts` MUST call `client.accounts()`.
- **accounts-text**: In text mode each account MUST print as one line `<email>  <status raw value>  <lastSyncAt or "never">`, separated by two spaces.
- **labels-call**: `labels <account>` MUST call `client.labels(account:)`.
- **labels-text**: In text mode each label MUST print as one line `<name>  <id>  <type>`, separated by two spaces.

### list

- **message-line**: Every command that prints a message in text mode (`list`, `thread` without `--bodies`, `label add`, `label remove`, `move`) MUST use one message line: `<date>  <id>  <from>  <subject>  [<label names joined by ", ">]`, with fields separated by two spaces, `date` printed exactly as the message's `date` field was received, and the label names always inside square brackets (`[]` when there are none).

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
- **list-text**: In text mode each message MUST print as a message line, and when the page has a `nextCursor` a final line `next cursor: <cursor>` MUST follow the message lines.
- **list-json**: In JSON mode the whole `MailMessagePage` MUST be encoded, including `nextCursor`.
- **list-ignored-filter**: When the client throws because the service ignored `--any-label` or `--query` (`MailClient` rejects a page whose `appliedAnyLabels` or `appliedQuery` is false), `run` MUST treat it as an ordinary failure: status 1, the message on `stderr`, nothing on `stdout`.

### get and thread

- **get-call**: `get <account> <id>` MUST call `client.message(account:id:)`.
- **get-text**: In text mode `get` MUST print the header lines `From:`, `To:` (recipients joined by ", "), `Date:` (the message's `date` field, as received), `Subject:` and `Labels:` (label names joined by ", "), a blank line, then the body.
- **body-fallback**: The body MUST be `bodyText` when present; otherwise the plain text converted from `bodyHtml` by `HTMLText.plainText(fromHTML:)` when that is non-empty; otherwise the `snippet`.
- **html-without-text**: HTML that converts to the empty string (an image-only message) MUST fall through to the snippet.
- **thread-call**: `thread <account> <id> [--bodies]` MUST call `client.thread(account:id:includeBodies:)`, where `id` is a thread id or the id of any message in the thread.
- **thread-text-summary**: Without `--bodies`, text mode MUST print a header `thread <thread id>  <n> message` (`messages` when n is not 1) followed by one message line (see **message-line**) per message in the order the client returned them.
- **thread-sent-marker**: A message whose `labels` contain `SENT` MUST be marked `(you)`: appended after two spaces on its message line without `--bodies`, and as a `(you)` line before its detail block with `--bodies`.
- **thread-text-bodies**: With `--bodies`, text mode MUST print the header and then each message's `get` detail block, with the blocks separated by a blank line, a line of four hyphens and a blank line.
- **thread-json**: In JSON mode the whole `MailThread` MUST be encoded.
- **thread-options**: `thread` MUST accept `--bodies` and `--json` only; any other `--` option MUST be a usage error.

### label add, label remove and move

- **label-verb**: `label` MUST require its first argument to be `add` or `remove`, otherwise a usage error.
- **label-arity**: `label add` and `label remove` MUST require at least three positionals after the verb (account, label, and one or more ids), otherwise a usage error.
- **label-call**: `label add` MUST call `client.modifyLabels` with the label as the only `add` entry and no `remove`; `label remove` MUST do the reverse; both MUST pass all ids in the order given.
- **label-options**: `label add` and `label remove` MUST accept only `--json` as an option; any other `--` option MUST be a usage error.
- **label-text**: In text mode `label add` and `label remove` MUST print one message line (see **message-line**) per returned message.
- **move-arity**: `move` MUST require at least two positionals (account and one or more ids) and exactly one `--to`, otherwise a usage error; zero or two `--to` are both usage errors.
- **move-from**: Each `--from` MUST be collected in order; with no `--from` the `from` argument MUST be nil (not an empty list) so the service applies its default of removing INBOX.
- **move-call**: `move` MUST call `client.moveMessages` with the account, the ids in the order given, the single `--to` value as `destination` and the collected `from`.
- **move-position-free**: `--to`, `--from` and ids MAY appear in any order after the account.
- **move-text**: In text mode `move` MUST print one line per `MailMoveResult`: the message line (see **message-line**), two spaces, then each added label as `+<name>` followed by each removed label as `-<name>`, separated by single spaces, or `(no change)` when both are empty.
- **move-json**: In JSON mode the array of `MailMoveResult` values MUST be encoded.

### Output encoding and concurrency

- **json-encoding**: JSON output MUST be produced by `MailJSON.encode`, pretty printed with sorted keys, as UTF-8 text; a failure to produce UTF-8 text is an encoding error reported as a failure (status 1).
- **one-client-call**: Each successful invocation MUST make exactly one call on the client.
- **no-shared-state**: `run` MUST hold no state between calls: parsing builds local values, so concurrent invocations with different clients do not interact.

## Appearance

Not applicable — this is a command-line parser and printer, not a visual component. Its only output is text written to the closures it is given.

## States

Not applicable — this is a command-line parser and printer, not a visual component. A single `run` call moves from parsing to executing to returning a status and keeps no state afterwards.

## Accessibility

Not applicable — this is a command-line parser and printer, not a visual component. Output is plain text on standard streams, which the host's terminal presents.

## Conformance Test Vectors

Test names are in `MailCommandLineTests` unless stated. `ScriptedMail` is the test double that answers every client call with a canned response and records the requests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mailcli-001 | help-request, usage-text | args `["--help"]`, `["-h"]`, `["help"]`, `["list", "--help"]`, `["label", "add", "-h"]` (helpPrintsUsageToStdoutAndSucceeds) | Status 0; `stdout` is exactly the usage text; `stderr` empty |
| mailcli-002 | usage-text | args `["--help"]` with `program: "{{app_name_lower}} mail"` (usageNamesTheCommandAsTheHostSpellsIt) | Output starts `usage: {{app_name_lower}} mail <command>`, contains `  {{app_name_lower}} mail list <account>` and has no line starting `  mail ` |
| mailcli-003 | command-selection, usage-error-status | args `["frobnicate"]` and `[]` (unknownSubcommandReturns64) | Status 64; for `frobnicate`, `stderr` is exactly the usage text |
| mailcli-004 | unknown-option, positional-count-fixed, usage-error-status | `["list", "a", "--bogus"]` then `["accounts", "--limit", "5"]` (unknownOptionIsUsageError) | Status 64 both times; `stderr` is the usage text; client receives no request |
| mailcli-005 | value-required | `["list", "a", O]` for each of `--since`, `--until`, `--label`, `--any-label`, `--limit`, `--cursor`, `--query` (optionMissingValueIsUsageError) | Status 64 for every option |
| mailcli-006 | list-call, list-date-bounds, list-label-options, list-limit-valid, list-cursor, list-bodies | `["list", "me@example.com", "--since", "2026-01-01", "--until", "2026-01-31", "--label", "Work", "--label", "INBOX", "--limit", "10", "--cursor", "20", "--bodies"]` (listParsesDateOnlyBounds) | Status 0; one request: filter with since `2026-01-01T00:00:00.000Z`, until `2026-01-31T23:59:59.999Z`, labels `["Work", "INBOX"]`, limit 10, cursor `20`, includeBodies true |
| mailcli-007 | list-date-bounds | `--since 2026-01-02T03:00:00+02:00 --until 2026-01-02T03:00:00.250Z` (timestampsAreConvertedToUTC) | since `2026-01-02T01:00:00.000Z`, until `2026-01-02T03:00:00.250Z` |
| mailcli-008 | list-date-invalid | `--since yesterday`; `--until 2026-13-45`; `--since 2026-02-30` (badDateIsUsageError, impossibleDateIsUsageError) | Status 64 each |
| mailcli-009 | list-limit-valid | `--limit` of `0`, `-3`, `abc` (badLimitIsUsageError) | Status 64 each |
| mailcli-010 | list-label-options | `["list", "a", "--any-label", "INBOX", "--label", "STARRED", "--any-label", "Projects/Inbox"]` (listParsesAnyLabelAsItsOwnRepeatableOption) | Filter labels `["STARRED"]`, anyLabels `["INBOX", "Projects/Inbox"]` |
| mailcli-011 | list-ignored-filter, failure-handling | `["list", "a", "--any-label", "INBOX"]` against a service reply with `appliedAnyLabels` false (anyLabelFromAServiceThatIgnoresItFailsInsteadOfListingEverything) | Status 1; `stdout` empty; `stderr` starts with `Error: ` (the exact wording belongs to `MailClient`'s own spec) |
| mailcli-012 | list-query-valid | `["list", "a", "--query", "from:example", "--label", "INBOX"]` (listPassesQueryToTheService) | Status 0; filter labels `["INBOX"]`, query `from:example` |
| mailcli-013 | list-query-blank | `--query ""` and `--query "   "` (blankQueryIsUsageError) | Status 64 each; no client request |
| mailcli-014 | list-ignored-filter | `["list", "a", "--query", "from:x"]` against a service reply with `appliedQuery` false (queryFromAServiceThatIgnoresItFails) | Status 1; `stdout` empty |
| mailcli-015 | list-text, single-write | page with one message and `nextCursor` `50` (listPrintsMessagesAndNextCursor) | `stdout` is one string: `2026-01-02T03:04:05.000Z  m1  a@example.com  Hello  [Inbox, Work]` newline `next cursor: 50` |
| mailcli-016 | list-text, skip-empty-output | empty page with cursor `50`; then `accounts`, `labels`, `list` with empty results (emptyPageWithCursorPrintsOnlyCursor, emptyResultsPrintNothing) | First: `stdout` is `["next cursor: 50"]`. Others: status 0 and `stdout` never called |
| mailcli-017 | list-json, json-flag, json-encoding | `["list", "a", "--json"]` with `nextCursor` `50`; `["accounts", "--json"]` (listJSONIncludesNextCursor, jsonFlagEmitsJSON) | `stdout` is the `MailJSON` encoding of the page, containing `"nextCursor" : "50"`; accounts JSON lists `"email"` before `"id"` (sorted keys) |
| mailcli-018 | accounts-text | `["accounts"]` with one active account synced `2026-01-02T00:00:00.000Z` (accountsTextOutput) | `stdout` is `["me@example.com  active  2026-01-02T00:00:00.000Z"]` |
| mailcli-019 | labels-text | `["labels", "a"]` with labels Work/Label_1/user and INBOX/INBOX/system (labelsTextOutput) | `Work  Label_1  user` newline `INBOX  INBOX  system` |
| mailcli-020 | get-text | `["get", "a", "m1"]` (getTextOutput) | Output is `From: a@example.com`, `To: me@example.com`, `Date: 2026-01-02T03:04:05.000Z`, `Subject: Hello`, `Labels: Inbox, Work`, blank line, `body` |
| mailcli-021 | body-fallback | message with `bodyText` nil and `bodyHtml` `<style>x{}</style><p>Dear User,</p><p>It&#39;s a match.</p>` (getTextReadsHTMLWhenThereIsNoBodyText) | Output ends `Dear User,` blank line `It's a match.` |
| mailcli-022 | body-fallback | `bodyText` nil, no `bodyHtml` (getTextFallsBackToSnippet) | Output ends with a blank line then the snippet `snip` |
| mailcli-023 | html-without-text | `bodyText` nil, `bodyHtml` containing only a linked image (getTextFallsBackToSnippetWhenTheHTMLHasNoText) | Output ends with the snippet `snip` |
| mailcli-024 | thread-call, thread-text-summary, thread-sent-marker | `["thread", "a", "m1"]`, messages m1 (INBOX) and m2 (SENT) (threadMarksTheMessagesYouSent) | Request `getThread(account a, id m1, includeBodies false)`; output `thread t1  2 messages` then the m1 line then the m2 line ending `  (you)` |
| mailcli-025 | thread-text-bodies, thread-sent-marker | `["thread", "a", "t1", "--bodies"]` (threadWithBodiesPrintsEachMessageInFull) | Splitting on blank line, four hyphens, blank line gives 3 blocks: header; m1 detail starting `From: a@example.com` and ending `body m1`; m2 starting `(you)` newline `From: a@example.com` and ending `body m2` |
| mailcli-026 | thread-text-summary | thread with one message (threadOfOneSaysMessage) | Output starts `thread t1  1 message` followed by a newline (singular) |
| mailcli-027 | positional-count-fixed, thread-options | `["thread", "a"]`, `["thread", "a", "1", "2"]`, `["thread", "a", "1", "--limit", "2"]` (threadNeedsAnAccountAndOneId) | Status 64 each; no client request |
| mailcli-028 | label-call | `["label", "add", "a", "Work", "m1", "m2"]` and `["label", "remove", "a", "Work", "m1"]` (labelAddBuildsModifyRequest, labelRemoveBuildsModifyRequest) | `modifyLabels(account a, ids [m1, m2], add [Work], remove [])`; then `modifyLabels(account a, ids [m1], add [], remove [Work])` |
| mailcli-029 | label-arity, usage-error-status | `["label", "add", "a", "Work"]` (labelWithoutIdsIsUsageError) | Status 64; `stderr` is the usage text; no client request |
| mailcli-030 | move-call, move-from, move-position-free | `["move", "a", "m1", "m2", "--to", "Work"]`; `["move", "a", "--from", "INBOX", "m1", "--to", "Projects/Done", "--from", "Projects/Inbox"]` (moveBuildsMoveRequest) | First: ids `[m1, m2]`, destination `Work`, from nil. Second: ids `[m1]`, destination `Projects/Done`, from `["INBOX", "Projects/Inbox"]` |
| mailcli-031 | move-arity, value-required, unknown-option | `["move","a","m1"]`, `--to X --to Y`, `["move","a","--to","X"]`, `--to` last, `--from` last, `--bogus` (moveNeedsExactlyOneDestinationAndAnId) | Status 64 and `stderr` the usage text for each; no client request |
| mailcli-032 | move-text | `["move", "a", "m1", "m2", "--to", "Work"]` with results added Work removed INBOX and Later for m1, nothing for m2 (movePrintsWhatEachMessageGainedAndLost) | Line for m1 ends `[Work]  +Work -INBOX -Later`; line for m2 ends `[Work]  (no change)` |
| mailcli-033 | move-json, thread-json | `["move","a","m1","--to","Work","--json"]`; `["thread","a","m1","--json"]` (moveJSONIsTheResults, threadJSONIsTheThread) | `stdout` is the `MailJSON` encoding of the results array; of the thread |
| mailcli-034 | not-found-handling, not-found-status | `["get","a","zz"]`, `["label","add","a","Work","zz"]`, `["get","a","zz","--json"]` against `notFound("No message matches “zz”")` (notFoundMessageReturnsItsOwnStatus) | Status 3 each; `stderr` is `["Error: No message matches “zz”"]`; `stdout` empty |
| mailcli-035 | not-found-handling | `["thread","a","zz"]` and `["move","a","zz","--to","Work"]` with notFound (threadOfAnUnknownMessageExits3, moveOfAnUnknownMessageExits3) | Status 3; for move `stderr` is `["Error: No message matches “zz”"]` |
| mailcli-036 | failure-handling | `["accounts"]` against a client failure "boom" (remoteFailureReturns1) | Status 1; `stderr` is `["Error: boom"]` |
| mailcli-037 | usage-documents-exit-statuses, usage-documents-label-combination, usage-lists-commands | `MailCommandLine.usage()` (usageDocumentsExitStatuses, usageDocumentsHowLabelFiltersCombine, usageDocumentsThreadAndQuery) | Contains `3 a message id matches nothing`, `[--label L]... [--any-label L]...`, `every --label (AND)`, `[--query Q]` and `thread <account> <id> [--bodies]` |
| mailcli-038 | list-limit-clamp | `["list","a","--limit","9999"]` (derived from `MailMessageFilter.clamp`, not a named test) | Filter limit is 500 |
| mailcli-039 | value-consumption, repeated-option-last-wins | `["list","a","--limit","5","--limit","7"]` and `["list","a","--limit","-3"]` (derived from `split`, not a named test; the second is covered by badLimitIsUsageError) | First: limit 7. Second: status 64 |

## Edge Cases

- **Null and empty input**: An empty argument list MUST return 64 with the usage text on `stderr`. An empty-string positional (an account or id of `""`) is accepted by the parser and sent to the client; the client or service decides what it matches. The `list` empty page prints nothing and returns 0; an empty page with a cursor prints only `next cursor: <cursor>`. A blank `--query` MUST be a usage error.
- **Boundary values**: `--limit 0` and negative limits MUST be usage errors; `--limit` above 500 MUST be clamped to 500 by `MailMessageFilter`, not rejected. `--since 2026-02-30` MUST be a usage error; a date-only `--until` MUST end at `23:59:59.999Z`. A thread of exactly one message MUST say `1 message`.
- **Malformed input**: A `--limit` that is not an integer, a date in a shape other than `YYYY-MM-DD` or ISO-8601, an unknown `--` option and a missing option value MUST each return 64. A `--` token is never taken as a positional, but a value after a valued option is consumed even if it starts with `-`.
- **Help anywhere**: `-h` or `--help` anywhere, even as the value of another option, MUST print help and return 0; the check precedes parsing.
- **Duplicated options**: Repeating `--since`, `--until`, `--limit`, `--cursor` or `--query` uses the last value silently; repeating `--to` is a usage error.
- **Error states**: A `notFound` error MUST return 3; every other client or encoding error MUST return 1 with `Error: <localizedDescription>` on `stderr`. A service too old to apply `--any-label`, `--query` or threads surfaces as a status-1 failure through `MailClient`, never as an unfiltered listing.
- **Concurrent access**: `run` keeps no state between calls and holds no locks, and the host provides the `@Sendable` closures; two calls interleave only through their own clients and closures. One call is a single sequential `async` flow: parse, one client call, format, write.
- **Cancellation and timeouts**: `run` has no timeout and no cancellation handling of its own; cancelling the surrounding task is observed only if the client call throws, in which case the thrown error (including `CancellationError`) falls to the catch-all and maps to status 1 with its description on `stderr`. Cancellation is not a named requirement and has no test.
- **Offline or unreachable service**: `run` has no retry or offline handling; a transport failure thrown by the client MUST be reported as status 1 with its description on `stderr`. Retry behavior belongs to the host and the service.
- **Destructive operations**: `label add`, `label remove` and `move` change mail through the service on every call with no confirmation prompt and no idempotency key; the backend's response surfaces unchanged.
- **Partial results**: A client call that throws prints nothing to `stdout`, so no partial output precedes a failure.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | required | The arguments after `mail`, such as `["list", "me@example.com", "--limit", "10"]` |
| `program` | `String` | `"mail"` | How the host's users type the command, used in the usage text |
| `client` | `MailClient` | required | The injected client that performs every operation; it owns transport, timeouts and retries |
| `stdout` | `@Sendable (String) -> Void` | required | Receives the result, or the usage text for a help request; one call per successful run |
| `stderr` | `@Sendable (String) -> Void` | required | Receives usage text for a usage error and `Error: ...` lines for failures |
| `--json` | flag | off | Emit the client's value as pretty printed, key-sorted JSON |
| `--limit` | positive integer | filter default 50 | Page size, clamped to 1 through 500 |
| `notFoundStatus` | `Int32` constant | 3 | Exit status when a message id matches nothing |

The component reads no environment variables, settings keys or files.

## Deep Linking

Not applicable: `MailCommandLine` is a command-line parser with no URL, scheme or route handling.

## Localization

Not applicable beyond fixed English text: every string the code produces is hardcoded English and is not localized — the usage text, the `Error: ` prefix, `never`, `next cursor:`, `(no change)`, `(you)`, the `From:`, `To:`, `Date:`, `Subject:` and `Labels:` header names, and the `thread <id>  <n> message(s)` header. There is no string table, locale-aware formatting or plural rule beyond the single `message` versus `messages` choice. Dates are printed as the service returns them.

## Accessibility Options

Not applicable: the component writes plain text to the closures it is given and responds to no display or motion options.

## Feature Flags

Not applicable: the code reads no flags; behavior is determined by the arguments and the injected client.

## Analytics

Not applicable: the code emits no events or metrics.

## Privacy

- **Data collected**: None collected or retained. The component prints mail data the client returns (sender and recipient addresses, subjects, label names, bodies and snippets) and account email addresses to the supplied `stdout`.
- **Storage**: None; nothing is written to disk and no state is kept between calls.
- **Transmission**: The component sends nothing itself. Account names, label names, ids, search queries and date bounds go to the injected `MailClient`, which owns transport to the mail service. Message content goes only to `stdout` as the host wires it.
- **Retention**: Not applicable; the component retains nothing. Whatever the host does with the output is outside this code.

## Logging

Not applicable: the code makes no log calls. Failures are written to the `stderr` closure as the command's result, which is output, not logging.

## Platform Notes

- **SwiftUI**: Not a view. A SwiftUI app would not use a command line directly; if it needs the same operations it would call `MailClient` and bind the results to `@Observable` state, reusing the filter and date-bound rules rather than the printers.
- **Compose**: Not a view. A Kotlin port would expose the same operations on a client interface and could back a console tool with a `suspend fun run(args, program, client, stdout, stderr): Int`; parse arguments with a hand-written loop like `split` (a library such as Clikt prefers its own help and error statuses, which would have to be overridden to keep 0, 1, 3 and 64) and serialize with kotlinx.serialization using sorted keys.
- **React/Web**: Source is Swift only; a TypeScript port would be an `async function run(args: string[], opts)` returning `Promise<number>`, taking `stdout` and `stderr` callbacks, with the same `--`-prefix option rules and `JSON.stringify` of a key-sorted value with 2-space indentation. Single-threaded JavaScript removes the concurrency question. Replace `Calendar` and `ISO8601DateFormatter` with explicit UTC date validation, since `new Date("2026-02-30")` does not reject impossible dates.
- **AppKit / UIKit**: Source is `packages/apple/AgenticDeveloperHubSDK/Integrations/CLI/MailCommandLine.swift`, in the Integrations target. It depends on `AgenticDeveloperHubSDKCore` (for `HTMLText`) and `Foundation`, and on `MailClient`, `MailMessageFilter`, `MailJSON` and `MailDateBound` from the sibling `Integrations/Service` files. It is a caseless `public enum` with static methods, so there is nothing to instantiate and nothing for AppKit or UIKit; the `@Sendable` closure parameters let the host forward to `FileHandle.standardOutput` and `FileHandle.standardError`. Private `Command`, `Options` and `Parsed` types hold the parse result.
- **WinUI 3**: Build it as a .NET class library, a static class `MailCommandLine` with `public static string Usage(string program = "mail")` and `public static async Task<int> RunAsync(string[] args, string program, IMailClient client, Action<string> stdout, Action<string> stderr)`. Model `Command` as a C# record hierarchy and the parse result as a nullable tuple (null for a usage error). Do not use `System.CommandLine` unless it is configured to return 3 for not found and 64 for usage errors and to treat `--help` and `-h` anywhere as help. Print with the `Console.Out` and `Console.Error` supplied by the host `Program.Main`, returning the integer from `Main` as the process exit code. Encode JSON with `System.Text.Json.JsonSerializer` and `WriteIndented = true`; it has no built-in sorted-key option, so serialize through `JsonNode` after sorting properties explicitly to match the source's sorted keys. Map `MailClientError.notFound` to a `MailNotFoundException` caught before a general `Exception` handler that prints `Error: ` plus `ex.Message`. Parse date-only bounds with `DateTime.TryParseExact` using `yyyy-MM-dd` and `CultureInfo.InvariantCulture`, parse timestamps with `DateTimeOffset.TryParse`, then format with `ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")`. Use `HttpClient` only inside the injected client. Where the host is a WinUI 3 app, route `stdout` to a `TextBlock` or an `ObservableCollection<string>` log rather than a console.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/CLI/MailCommandLine.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

`MailCommandLine` keeps parsing and formatting apart from the transport by taking an injected `MailClient` and output closures, so separation-of-concerns passes. `MailCommandLineTests` asserts every command, the main usage-error paths, the exit statuses and the text and JSON forms, so unit-test-coverage is partial. Mailcli-038 and mailcli-039 are derived from the source, not named tests, and no vector covers `single-dash-positional`, the `--json` placement errors, `label-verb`, `label-options`, `label-text`, `list-any-label-with-query`, `one-client-call`, `no-shared-state` or the UTF-8 failure path of `json-encoding`. Every thrown error is mapped to a status and a message on `stderr`, so explicit-error-handling passes. Input sanitization is partial: limits, dates and blank queries are validated, but account names, label names and ids are forwarded unmodified for the client and service to validate. No-hardcoded-strings fails because every user-facing string is English text in the source, with no externalization; this is a deliberate property of a developer command line, recorded under Localization.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
