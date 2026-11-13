---
id: cbee8b02-9456-4d9b-942a-51f8a9c074fc
title: "MailToolSource"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The seven mail tools an MCP host offers over a MailClient: JSON-schema definitions, strict argument parsing, and pretty-printed sorted-key JSON or error results."
platforms:
  - swift
  - macos
tags:
  - integrations
  - mcp
  - mail
  - tool-source
depends-on:
  - 3d12c073-edc3-44fb-a988-5edec20575e0
  - fc9671be-170c-436e-9628-892624952191
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# MailToolSource

## Overview

`MailToolSource` is a value type conforming to `ChatToolSource` that exposes a mail account service to a chat engine or MCP host as seven tools. It holds one `MailClient` and nothing else. It advertises each tool's name, description and JSON-schema parameters, then turns a tool call's JSON arguments into a typed `MailClient` call and the typed result back into text.

Results are pretty-printed JSON with sorted keys (the shared `MailJSON.encode` shape that the mail command-line tool's `--json` flag also prints). A bad argument or a service failure comes back as an error result, never as a thrown error. The tools are `mail_list_accounts`, `mail_list_labels`, `mail_list_messages`, `mail_get_message`, `mail_get_thread`, `mail_modify_labels` and `mail_move_messages`.

## Behavioral Requirements

### Construction and conformance

- **client-injection**: The component MUST be constructed with exactly one `MailClient` and MUST perform every mail operation through it.
- **tool-source-conformance**: The component MUST conform to the host's tool-source contract by providing a tool-definition list and a call operation taking a tool name and the argument bytes.
- **caller-ignored**: When the host supplies a caller identifier, the component MUST ignore it.
- **stateless**: The component MUST hold no mutable state, so that it can be shared between concurrent calls; each call MUST be independent of every earlier call.

### Tool definitions

- **tool-list-order**: `toolDefinitions()` MUST return exactly seven definitions in this order: `mail_list_accounts`, `mail_list_labels`, `mail_list_messages`, `mail_get_message`, `mail_get_thread`, `mail_modify_labels`, `mail_move_messages`.
- **schema-shape**: Each definition's `parametersJSONSchema` MUST be a JSON object schema with a `properties` map and a `required` array.
- **list-accounts-schema**: `mail_list_accounts` MUST declare no properties and no required arguments.
- **account-argument**: Every tool except `mail_list_accounts` MUST declare a string property `account` ("The account's connection id or email address.") and MUST list it as required.
- **list-labels-required**: `mail_list_labels` MUST require only `account`.
- **list-messages-schema**: `mail_list_messages` MUST declare `account` (string, required), `since`, `until`, `cursor` and `query` (strings), `labels` and `any_labels` (string arrays), `limit` (integer) and `include_bodies` (boolean).
- **get-message-required**: `mail_get_message` MUST declare `account` and `id` as required strings, and MUST NOT declare `include_bodies`.
- **get-thread-schema**: `mail_get_thread` MUST declare `account` and `id` (strings, both required) and `include_bodies` (boolean).
- **modify-labels-schema**: `mail_modify_labels` MUST declare `account` (string, required), `message_ids` (string array, required), `add` and `remove` (string arrays).
- **move-messages-schema**: `mail_move_messages` MUST declare `account` (string), `message_ids` (string array) and `to` (string), all required, and `from` (string array).
- **schema-not-enforced**: The component MUST NOT rely on the advertised schema for validation; required and typed arguments are checked again when a call arrives.

### Call dispatch

- **argument-decoding**: `callTool` MUST parse `argumentsJSON` as a JSON object; when the data is not valid JSON, or is JSON but not an object, the component MUST treat the arguments as an empty dictionary.
- **result-shape**: `callTool` MUST return a `(content, isError)` pair and MUST NOT throw.
- **success-result**: On success the component MUST return the encoded result with `isError` false.
- **argument-error-result**: A rejected argument MUST return the error's message text as `content` with `isError` true.
- **service-error-result**: Any other error, including a `MailClientError` from the client, MUST return the error's `localizedDescription` as `content` with `isError` true.
- **unknown-tool**: A name outside the seven MUST return `unknown tool <name>` with `isError` true and MUST NOT call the client.
- **no-client-call-on-bad-arguments**: When argument validation fails, the component MUST NOT call the client.

### Result encoding

- **json-format**: A result MUST be encoded by the shared mail JSON encoder as pretty-printed JSON with sorted keys, so object keys appear in alphabetical order regardless of declaration order.
- **result-types**: `mail_list_accounts` MUST return the encoded array of `MailAccount`; `mail_list_labels` the array of `MailLabel`; `mail_list_messages` a `MailMessagePage`; `mail_get_message` a `MailMessage`; `mail_get_thread` a `MailThread`; `mail_modify_labels` an array of `MailMessage`; `mail_move_messages` an array of `MailMoveResult`.
- **encoding-failure**: A value that cannot be encoded, or whose bytes are not UTF-8, MUST surface as an error result through the service-error path.

### Argument parsing

- **required-string**: A required string argument MUST be present, MUST be a JSON string and MUST be non-empty; otherwise the error is `missing required argument: <key>` when absent or empty, or `<key> must be a string` when present with another type.
- **optional-string**: An optional string argument that is absent MUST yield no value; when present with a non-string type the error MUST be `<key> must be a string`.
- **string-array**: An array argument that is absent MUST yield an empty array; when present and not an array of strings the error MUST be `<key> must be an array of strings`.
- **boolean-strict**: `include_bodies` MUST default to false when absent; a JSON number MUST NOT count as a boolean, and a non-boolean MUST yield `include_bodies must be a boolean`.
- **integer-strict**: `limit` MUST be a JSON number with no fractional part and MUST NOT be a boolean; otherwise, or when it is zero or negative, the error MUST be `limit must be a positive integer`.
- **date-bounds**: `since` and `until` MUST be read by the shared date-bound normaliser, with `since` at the start edge and `until` at the end edge; a value that is not `YYYY-MM-DD` or an ISO-8601 timestamp, or a calendar date that does not exist, MUST yield `<key> must be YYYY-MM-DD or an ISO-8601 timestamp`.
- **date-only-expansion**: A `YYYY-MM-DD` value MUST become `<date>T00:00:00.000Z` for `since` and `<date>T23:59:59.999Z` for `until`, the start and end of that UTC day.
- **timestamp-utc**: An ISO-8601 timestamp, with or without fractional seconds, MUST be converted to UTC in the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **unknown-arguments-ignored**: An argument the tool does not declare MUST be ignored.

### mail_list_messages

- **filter-mapping**: The component MUST build one `MailMessageFilter` from `account`, `since`, `until`, `labels`, `any_labels`, `limit`, `cursor`, `include_bodies` and `query`, and call `client.messages` once with it.
- **limit-default**: When `limit` is absent the filter MUST keep `MailMessageFilter.defaultLimit` (50).
- **limit-clamp**: A positive `limit` above 500 MUST be accepted by the tool and clamped into `MailMessageFilter.limitRange` (1 to 500) by the filter, not rejected.
- **query-not-blank**: A `query` that is present and, once trimmed of whitespace and newlines, empty MUST yield `query must not be empty`; a non-blank query MUST be passed to the filter as written, untrimmed.
- **any-labels-with-query**: The tool MUST pass `any_labels` and `query` through together without checking the combination; `MailClient.messages` rejects the service reply when the service did not apply them.

### mail_get_message and mail_get_thread

- **get-message-call**: `mail_get_message` MUST call `client.message` with the required `account` and `id`.
- **get-thread-call**: `mail_get_thread` MUST call `client.thread` with `account`, `id` and the parsed `include_bodies` (false by default).

### mail_modify_labels

- **modify-ids-required**: `message_ids` MUST be a non-empty array of strings; an empty array MUST yield `message_ids must not be empty`.
- **modify-needs-change**: At least one of `add` or `remove` MUST be non-empty, otherwise the error is `give at least one label in add or remove`.
- **modify-validation-order**: The component MUST read `account`, `message_ids`, `add` and `remove` (type errors first) before it checks that `message_ids` is non-empty and then that `add` or `remove` is non-empty.
- **modify-call**: A valid call MUST invoke `client.modifyLabels` once with the account, ids, `add` and `remove`.

### mail_move_messages

- **move-required**: `account`, `message_ids` and `to` MUST be present; an empty `message_ids` MUST yield `message_ids must not be empty`.
- **move-from-absent**: When `from` is absent the component MUST pass `nil` to the client, which the schema description defines as INBOX (when `from` is absent and `to` is INBOX, no label is removed).
- **move-from-empty**: When `from` is present and empty the component MUST pass an empty array, which the schema description defines as "nothing, so the label is only added".
- **move-from-type**: A `from` that is present and not an array of strings MUST yield `from must be an array of strings`.
- **move-call**: A valid call MUST invoke `client.moveMessages` once with the account, ids, destination and `from`.

### Concurrency, persistence and side effects

- **concurrency**: The component MUST be safe to share across concurrent tasks (in Swift, `Sendable`), and every operation that reaches the client MUST be asynchronous.
- **no-serialisation**: The component MUST NOT serialise concurrent calls; any ordering between them is the service's.
- **no-persistence**: The component MUST NOT write files, cache results or keep tokens; its only side effects are the `MailClient` requests.
- **write-tools**: Each `mail_modify_labels` or `mail_move_messages` call MUST make exactly one client request, with no idempotency key, and MUST return the service's response unchanged; both change the user's mail at the mail service.
- **no-timeout-no-retry**: The component MUST NOT add a timeout, cancellation hook or retry around the client call; those belong to the `MailClient` transport and the host.

## Appearance

Not applicable — this is a tool source, not a visual component.

## States

Not applicable — this is a tool source, not a visual component. It has no runtime state machine; each call either returns a success result or an error result.

## Accessibility

Not applicable — this is a tool source, not a visual component.

## Conformance Test Vectors

Vectors derive from `MailToolSourceTests` (Swift Testing) and from the source where a vector is noted as having no test. `ScriptedMail` is the test double behind `MailClient`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-tool-source-001 | tool-list-order | `toolDefinitions()` (test `listsSevenTools`) | names equal the seven names in the stated order |
| mail-tool-source-002 | filter-mapping, date-only-expansion, timestamp-utc | `mail_list_messages` with account `me@example.com`, since `2026-01-01`, until `2026-01-31T10:00:00Z`, labels `Work`, `INBOX`, limit 25, cursor `50`, include_bodies true (test `listMessagesMapsArguments`) | not an error; one filter with since `2026-01-01T00:00:00.000Z`, until `2026-01-31T10:00:00.000Z`, the labels, limit 25, cursor `50`, includeBodies true |
| mail-tool-source-003 | timestamp-utc | since `2026-01-02T03:00:00+02:00` (test `timestampsAreConvertedToUTC`) | filter since is `2026-01-02T01:00:00.000Z` |
| mail-tool-source-004 | filter-mapping, string-array | `labels` `["STARRED"]`, `any_labels` `["INBOX","Job Search/00. Inbox"]` (test `listMessagesMapsAnyLabels`) | not an error; filter carries both lists |
| mail-tool-source-005 | string-array | `any_labels` is the string `INBOX` (test `listMessagesMapsAnyLabels`) | error, content `any_labels must be an array of strings` |
| mail-tool-source-006 | filter-mapping | `query` `from:greenhouse` (test `listMessagesMapsQuery`) | not an error; filter query is `from:greenhouse` |
| mail-tool-source-007 | query-not-blank | `query` is two spaces (test `listMessagesMapsQuery`) | error, content `query must not be empty` |
| mail-tool-source-008 | integer-strict, boolean-strict, date-bounds, optional-string, no-client-call-on-bad-arguments | each of `limit` 0, `limit` true, `limit` 2.5, `limit` `"5"`, since `yesterday`, until `2026-02-30`, since 20260101, until true, cursor 5, include_bodies `"yes"` (test `badArgumentTypesAreErrors`) | every call is an error and the client receives no request; by the source the messages are `limit must be a positive integer` (first four), `since must be YYYY-MM-DD or an ISO-8601 timestamp`, `until must be YYYY-MM-DD or an ISO-8601 timestamp`, `since must be a string` (the number 20260101 is not a string, so the date check is never reached), `until must be a string`, `cursor must be a string` and `include_bodies must be a boolean` (the test asserts only the error and the absent request) |
| mail-tool-source-009 | integer-strict | `limit` true (test `badLimitMessage`) | content `limit must be a positive integer` |
| mail-tool-source-010 | required-string, no-client-call-on-bad-arguments | `mail_list_labels` with `{}` (test `missingArgumentIsError`) | error, content `missing required argument: account`, no request |
| mail-tool-source-011 | get-thread-call, json-format | `mail_get_thread` account `a`, id `m1`, then id `t1` with include_bodies true (test `getThreadMapsArguments`) | first result equals the encoded thread; requests are getThread with includeBodies false, then true |
| mail-tool-source-012 | required-string | `mail_get_thread` with only `account` (test `getThreadMapsArguments`) | error, content `missing required argument: id` |
| mail-tool-source-013 | json-format, result-types | `mail_get_message` account `a`, id `m1` (test `resultsArePrettySortedJSON`) | content equals the pretty sorted encoding and `"account"` appears before `"id"` |
| mail-tool-source-014 | modify-needs-change | `mail_modify_labels` with `message_ids` `["m1"]` and neither `add` nor `remove` (test `modifyRequiresAddOrRemove`) | error, no request |
| mail-tool-source-015 | modify-call | `message_ids` `["m1","m2"]`, `add` `["Work"]` (test `modifyMapsArguments`) | not an error; request modifyLabels with remove empty |
| mail-tool-source-016 | service-error-result | client replies not found `No message matches “zz”` (test `notFoundIsAnErrorResult`) | error, content is that text |
| mail-tool-source-017 | service-error-result | client replies failure `unknown label: Nope` to `mail_list_accounts` (test `toolErrorSurfacesRemoteFailure`) | error, content `unknown label: Nope` |
| mail-tool-source-018 | move-from-absent, move-from-empty, move-call, json-format | `mail_move_messages` with no `from`, then `from` `["Later"]`, then `from` `[]` (test `moveMapsArguments`) | requests carry from nil, `["Later"]`, `[]`; first result equals the encoded results |
| mail-tool-source-019 | move-required, modify-ids-required, move-from-type | missing `to`; empty `message_ids`; `from` the string `INBOX` (test `moveRejectsBadArguments`) | contents `missing required argument: to`, `message_ids must not be empty`, `from must be an array of strings`; no request |
| mail-tool-source-020 | unknown-tool | `callTool` name `mail_nope`, `{}` | error, content `unknown tool mail_nope` (derived from source; no test) |
| mail-tool-source-021 | argument-decoding | `mail_list_labels` with data `not json` | error, content `missing required argument: account` (derived from source; no test) |
| mail-tool-source-022 | limit-clamp | `mail_list_messages` with limit 1000 | not an error; filter limit is 500 (derived from `MailMessageFilter.clamp`; no test) |
| mail-tool-source-023 | required-string | `mail_list_labels` with `account` 5 | error, content `account must be a string` (derived from source; no test) |
| mail-tool-source-024 | required-string | `mail_list_labels` with `account` `""`; `mail_get_message` with `id` `""`; `mail_move_messages` with `to` `""` | each is an error, content `missing required argument: <key>` for `account`, `id` and `to` (derived from source; no test) |
| mail-tool-source-025 | boolean-strict | `mail_get_thread` with `include_bodies` 1 | error, content `include_bodies must be a boolean`, no request (derived from source; no test) |
| mail-tool-source-026 | modify-validation-order | `mail_modify_labels` with `message_ids` `[]` and `add` the string `Work`; then `message_ids` `[]` and no `add` or `remove` | first content `add must be an array of strings` (type error before the empty check); second `message_ids must not be empty` (derived from source; no test) |
| mail-tool-source-027 | schema-shape, list-accounts-schema, account-argument, get-message-required | `toolDefinitions()` | `mail_list_accounts` has an empty `properties` and empty `required`; every other tool has a string `account` and lists it in `required`; `mail_get_message` requires `account` and `id` and has no `include_bodies` property (derived from source; no test) |
| mail-tool-source-028 | argument-decoding, integer-strict, required-string | `mail_list_messages` with `{"account":"a","limit":null}`; `mail_list_labels` with `{"account":null}`; `mail_list_messages` with `{"account":"a","labels":null}` | contents `limit must be a positive integer`, `account must be a string`, `labels must be an array of strings`; no request (derived from source; no test) |
## Edge Cases

- **Malformed arguments**: Invalid JSON or a non-object JSON value MUST be read as an empty dictionary, so the call fails with the first missing required argument rather than a parse error. A tool that needs no arguments (`mail_list_accounts`) still runs.
- **Empty required string**: An empty `account`, `id` or `to` MUST be treated as missing.
- **Null values**: A JSON null for `limit` is neither a number nor a boolean and is therefore rejected with `limit must be a positive integer`; a null string is rejected with `<key> must be a string`.
- **Fractional or boolean limit**: `2.5` and `true` MUST be rejected; `limit` of zero or less MUST be rejected; a limit above 500 MUST be accepted and clamped to 500.
- **Impossible calendar date**: `2026-02-30` MUST be rejected, not rolled over into March.
- **Date-only until**: The upper bound covers the whole day through `23:59:59.999Z`.
- **Inverted range**: A `since` later than `until` is not checked; the component passes both on and the service decides.
- **Empty id arrays**: `message_ids` empty MUST be rejected for both write tools; an `add` or `remove` array containing empty strings is not checked here.
- **Both change lists empty**: `mail_modify_labels` with empty `add` and empty `remove` MUST be rejected.
- **Unknown or extra input**: An unknown tool name MUST be an error result; extra arguments MUST be ignored.
- **Unencodable result**: A result the encoder cannot encode, or whose bytes are not UTF-8, is thrown by the encoder and comes back as an error result with its description. No test double can produce one, so no vector covers it.
- **Error flow**: A service failure, a not-found reply, a thread request to an older service, a reply of the wrong shape or a query or `any_labels` the service ignored all arrive as a thrown `MailClientError` and MUST come back as an error result carrying its description.
- **Unreachable or slow service**: A transport failure surfaces as an error result with the transport error's `localizedDescription`; the component sets no timeout and does not retry. Offline behavior belongs to the transport.
- **Concurrent calls**: Calls are independent and unserialised. Two writes to the same message have whatever outcome the service gives them; this component adds no ordering rule.
- **Cancellation**: Cancelling the awaiting task is the client's business; the component installs no handler and does not catch cancellation separately.
- **Large results**: A page of up to 500 messages with bodies is returned whole as one string; the component does not truncate.

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `MailClient` | none (required) | The mail service client every tool call goes through; supplied to `init(client:)` |

The component reads no environment variables or settings keys. Per-call tool arguments (`limit`, `include_bodies`, `from` and the rest) are not construction options; their defaults are in the requirements above.
## Deep Linking

Not applicable: the component exposes tools by name and has no URLs or routes (`MailToolSource` has no navigation code).

## Localization

Not applicable as a catalogue: every tool description, schema description and argument error is a hardcoded English string in `MailToolSource`, with no string table. A service error is passed through as the client's `localizedDescription`.

## Accessibility Options

Not applicable: the component renders nothing and reads no display setting.

## Feature Flags

Not applicable: the seven tools are always advertised and no flag is read.

## Analytics

Not applicable: the component emits no events.

## Privacy

- **Data collected**: Not applicable as collection; the component reads the user's mail (accounts, labels, messages, bodies, threads) through the client and returns it to the tool caller.
- **Storage**: None; the component keeps nothing between calls.
- **Transmission**: Results go to whatever chat engine or MCP host called the tool, so message content leaves the service boundary for that host. Transport to the service is the `MailClient`'s.
- **Retention**: Not applicable; nothing is retained.

## Logging

Not applicable: the component makes no log calls.

## Platform Notes

- **SwiftUI**: Source is `MailToolSource.swift` in the Integrations module, with `ChatToolSource` and `ToolJSONSchema` from Core (schemas come from `ToolJSONSchema.object`, results from `MailJSON.encode`, date bounds from `MailDateBound.normalize`); there is no view, so SwiftUI is not involved. A SwiftUI app injects the `MailClient` and hands the source to its chat engine.
- **Compose**: Use a Kotlin class implementing the host's tool interface, `kotlinx.serialization.json` to parse arguments into a `JsonObject` (checking `isString` and numeric primitives to keep the boolean-versus-integer rule), a suspend function for `callTool`, and `Result` or a sealed error type instead of throwing. Pretty-printed sorted output needs a custom `Json` with `prettyPrint` and sorted map keys; there is no built-in key sorting.
- **React/Web**: Use a TypeScript class with an `async callTool(name, argsJson)` returning an object with `content` and `isError`. Parse with `JSON.parse` inside try/catch, check `typeof` and `Number.isInteger` (booleans are already distinct from numbers), and emit `JSON.stringify` with a replacer that sorts keys and two-space indentation. Express the schemas as plain JSON Schema objects.
- **AppKit / UIKit**: Same source file; it uses `JSONSerialization`, `NSNumber` with `CFBooleanGetTypeID` to tell booleans from numbers, `ISO8601DateFormatter` (to parse timestamps), `Date.ISO8601FormatStyle` (to write the UTC string, through `IntegrationClock`) and `JSONEncoder` with `.prettyPrinted` and `.sortedKeys`. No AppKit or UIKit type is used.
- **WinUI 3**: Implement as a plain .NET class with `async Task<(string Content, bool IsError)> CallToolAsync(string name, string argumentsJson)`. Parse arguments with `System.Text.Json` (`JsonDocument` and `JsonElement.ValueKind`: `JsonValueKind.True` and `False` for booleans, `Number` with `TryGetInt32` for integers so that `2.5` and `true` fail), and treat invalid JSON or a non-object root as an empty element. Encode results with `JsonSerializer` using `WriteIndented = true`; .NET does not sort keys, so sort properties explicitly (a `JsonNode` tree ordered by key, or a custom converter) to match the Swift output. Use `DateTimeOffset.TryParseExact` and `ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")` for the date bounds, and validate `YYYY-MM-DD` with `DateOnly.TryParseExact` so `2026-02-30` is rejected. The `MailClient` becomes an interface over `HttpClient` or a named-pipe transport, called with `await`; catch `Exception` at the `CallToolAsync` boundary and return its `Message`. Register as a singleton in dependency injection; no `ObservableCollection` or `INotifyPropertyChanged` is needed because the component has no observable state. If the host is a server, expose it as ASP.NET Core minimal API routes or an MCP endpoint wrapping the same method.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/MCP/MailToolSource.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Argument failures and service failures are both returned as error results, never thrown.
**Rationale**: The model that called the tool can read an error result and correct its next call, whereas a thrown error would abort the host's tool loop.
**Approved**: pending

**Decision**: Arguments are re-validated in code and the advertised schema is not trusted; booleans are kept distinct from numbers.
**Rationale**: Hosts and models do not reliably honour a schema, and a platform JSON parser may treat `true` as the number 1, so `limit: true` would otherwise be accepted as a page size of 1. (In Swift both bridge to `NSNumber`; see Platform Notes.)
**Approved**: pending

**Decision**: Invalid or non-object argument JSON becomes an empty dictionary instead of its own error.
**Rationale**: The call then fails with the first missing-argument message, which keeps one failure path and tells the model what to supply, instead of adding a second parse-error message for a case the model rarely causes.
**Approved**: pending

**Decision**: `since` and `until` are normalised to UTC strings with millisecond precision; a bare date spans the whole UTC day.
**Rationale**: The message store compares UTC date strings lexically, so every bound must have the same fixed-width form for the comparison to be correct.
**Approved**: pending

**Decision**: Only a limit of zero or less is rejected; a limit above 500 is clamped by `MailMessageFilter`.
**Rationale**: The filter already owns the page-size range, so keeping the clamp there leaves one place to change it; the tool rejects only values no range could accept.
**Approved**: pending

**Decision**: The tool does not check `any_labels` against `query`; the client does.
**Rationale**: Only the client knows whether the service honoured the combination, so the check lives where the reply is seen and reaches the caller as an error result.
**Approved**: pending

**Decision**: `from` distinguishes absent from empty by passing `nil` or an empty array.
**Rationale**: The two cases mean different things (move out of INBOX versus only add the label), and collapsing them would make "add only" impossible to request.
**Approved**: pending

**Decision**: No timeout, cancellation, retry or logging is added in this layer.
**Rationale**: The transport owns timeouts and retries so that retry policy stays in one place, and the host owns cancellation and logging; a second layer here would double-retry and hide which layer gave up.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |

The component keeps parsing, dispatch and encoding in one small type and leaves transport, storage and date normalisation to `MailClient`, `MailDateBound` and `MailJSON`, so separation-of-concerns passes. `MailToolSourceTests` covers the tool list, argument mapping for the list, thread, modify and move tools, the failure path and some argument error messages, but the unknown-tool name, the clamp, empty strings, null arguments, the schema shapes and the validation order have no test, so unit-test-coverage is partial. Errors are always returned as results with their message, so error handling passes. Argument types, required fields, date shapes and the limit are validated, but label names, message ids and the query text are passed on unchecked for the service to judge, so input-sanitization is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
