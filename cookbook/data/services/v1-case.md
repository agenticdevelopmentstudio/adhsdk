---
id: 92720f75-89b0-484f-8c0c-403fadc40179
title: "V1 Case"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wire boundary for /v1 clients with camelCase row types: key re-casing in both directions, unix-second to ISO timestamps, opaque free-form maps, and thin fetch wrappers."
platforms:
  - typescript
  - web
tags:
  - data
  - http
  - serialization
depends-on:
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
related:
  - ec6e6ca5-8780-4ce2-8b3a-087adc50ed35
references:
  - packages/web/packages/data/src/v1-case.ts (adhsdk)
  - packages/web/packages/data/src/http.ts (adhsdk)
  - packages/web/packages/auth/src/v1.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# V1 Case

## Overview

The `/v1` API speaks snake_case and reports `created` and `updated` as unix seconds. A client whose app-facing row types are camelCase keeps those types untouched and maps at the network edge with this module. It has two pure mappers and four thin wrappers that fetch through the shared authenticated request layer and map the result.

- `fromV1` turns a `/v1` object, or an array of them, into the camelCase row the client was written against.
- `toV1Body` turns a camelCase request body into the snake_case body `/v1` accepts.
- `v1Write`, `v1Json`, `v1List` and `v1Page` compose those mappers with `authedJson`, `listAllV1` and `listV1Page`, which this module imports from the data package's `http` module (a re-export of the auth package's client).

The source's header comment explains why the mapping is not a plain case conversion. The gateway renames only the properties the legacy spec declares. A property it does not know, such as a work item's `itemKey` or an iteration row's `projectName`, passes through in camelCase. So `fromV1` camelizes idempotently: `project_id` and `projectId` both land on `projectId`. Free-form maps keep the keys they were stored with and are never re-cased.

This is shared code with no visual surface. Authentication, token refresh, pagination cursoring, and HTTP error construction belong to the auth package's client and are described by [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104).

## Behavioral Requirements

Key mapping, shared by both directions:

- **mapper-pure**: `fromV1` and `toV1Body` MUST NOT mutate their input; each MUST return a new structure for every object and array it traverses.
- **array-recursion**: Both mappers MUST map each element of an array independently and return an array of the same length.
- **scalar-passthrough**: Both mappers MUST return a `null` value, a primitive value, or `undefined` input unchanged.
- **undefined-dropped**: Both mappers MUST omit any object property whose value is `undefined`.
- **null-kept**: Both mappers MUST keep a property whose value is explicit `null`, because on a write `null` clears a column.
- **recursion-depth**: Both mappers MUST apply the key renaming to nested objects and to objects inside arrays at any depth, except inside an opaque value.
- **opaque-keys**: When a property's original key is one of `config`, `detail`, `body`, `value` or `counts`, both mappers MUST copy its value to the output without traversing or re-casing it.
- **opaque-key-renamed**: An opaque property's own key MUST still be renamed by the direction's rename function; for the five opaque names this leaves the key unchanged.
- **opaque-matches-original-key**: Opaque detection MUST test the key as it arrived, before renaming.
- **later-key-wins**: When two input keys rename to the same output key, the property visited later in the input's own key order MUST overwrite the earlier one, with no error or warning.

Reading, `fromV1`:

- **camelize-rule**: `fromV1` MUST rename each key by replacing every underscore followed by a lowercase letter or digit with that character uppercased.
- **camelize-idempotent**: `fromV1` MUST leave a key that contains no underscore-then-lowercase-or-digit sequence unchanged, so applying it to an already-camelCase key is a no-op.
- **object-tag-dropped**: `fromV1` MUST omit every property whose key is exactly `object`, at any non-opaque depth, because it is the `/v1` type tag and not data.
- **timestamps-to-iso**: `fromV1` MUST replace a numeric `created` property with `createdAt` and a numeric `updated` property with `updatedAt`, each holding `unixToIso` of the number.
- **timestamp-nonfinite-null**: When `created` or `updated` is a number that is not finite, `fromV1` MUST emit `createdAt` or `updatedAt` as `null`, because `unixToIso` returns `null` for non-finite input.
- **timestamp-nonnumber-passthrough**: When `created` or `updated` is not a number, including `null`, `fromV1` MUST treat it as an ordinary key and emit it under its own name (`created` or `updated`), not under `createdAt` or `updatedAt`.
- **fromv1-unchecked-cast**: `fromV1<T>` MUST return its result typed as `T` without validating the shape.

Writing, `toV1Body`:

- **snakeize-rule**: `toV1Body` MUST rename each key by replacing every uppercase ASCII letter with an underscore followed by its lowercase form.
- **snakeize-idempotent**: `toV1Body` MUST leave an already-snake_case key unchanged.
- **object-key-kept-on-write**: `toV1Body` MUST NOT drop a property named `object`.
- **timestamps-untouched-on-write**: `toV1Body` MUST NOT convert `created` or `updated` values; a `createdAt` key becomes `created_at` with its value unchanged.

Fetch wrappers:

- **v1write-shape**: `v1Write` MUST return a `RequestInit` with `method` set to the given method and `body` set to `JSON.stringify(toV1Body(body))`.
- **v1write-post-only**: The `method` parameter of `v1Write` MUST be typed as the literal `"POST"`.
- **v1write-no-headers**: `v1Write` MUST NOT set `headers`; the request layer supplies `Content-Type: application/json` when a body is present.
- **v1json-single**: `v1Json` MUST call `authedJson` once with the given `url` and `init`, and return the response mapped by `fromV1`.
- **v1json-errors-propagate**: `v1Json` MUST let any error from `authedJson` (a non-ok status, or the 204 refusal) reach the caller unchanged and unmapped.
- **v1list-all-pages**: `v1List` MUST fetch every page of the collection through `listAllV1` with its default request init and default cursor, then map the combined rows with `fromV1` once.
- **v1list-cursor-on-wire-rows**: `v1List` MUST page on the raw wire rows' `id`, because mapping happens only after all pages are collected.
- **v1page-one-page**: `v1Page` MUST fetch exactly one page through `listV1Page` and return `{ data, hasMore }` with `data` mapped by `fromV1` and `hasMore` passed through unmapped.
- **v1page-url-verbatim**: `v1Page` MUST NOT add `limit` or `starting_after` to the url.
- **no-state**: The module MUST hold no mutable module state, so concurrent calls cannot affect each other.
- **no-retry-timeout-cancel**: The wrappers MUST NOT add their own timeout, retry, cancellation or caching; they inherit exactly what `authedJson`, `listAllV1` and `listV1Page` do.

Concurrency and ordering: the mappers are synchronous and pure. The async wrappers hold no shared state, so any number may run in parallel; each awaits its own fetch before mapping. Pagination inside `v1List` is sequential, one page awaited before the next is requested, because the next `starting_after` depends on the previous page.

Persistence and side effects: the mappers have none. The wrappers' only side effect is the network request issued by the underlying request layer. Nothing is written to disk and nothing is cached here.

## Appearance

Not applicable — this is a data-mapping and request-wrapper module, not a visual component.

## States

Not applicable — this is a data-mapping and request-wrapper module, not a visual component.

## Accessibility

Not applicable — this is a data-mapping and request-wrapper module, not a visual component.

## Conformance Test Vectors

`packages/web/packages/data/src/__tests__/v1-case.test.ts` asserts every vector below directly (stubbing `fetch` with `src/__tests__/v1-fetch.ts`); the projects client tests under `src/projects/__tests__/` also run the mappers indirectly. A port's unit tests should assert the same vectors.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| v1-case-001 | camelize-rule, timestamps-to-iso | `fromV1({ id: "p1", project_id: "x", created: 1700000000, updated: 1700000060 })` | `{ id: "p1", projectId: "x", createdAt: "2023-11-14T22:13:20.000Z", updatedAt: "2023-11-14T22:14:20.000Z" }` |
| v1-case-002 | camelize-idempotent | `fromV1({ project_id: "a" })` and `fromV1({ projectId: "a" })` | Both return `{ projectId: "a" }` |
| v1-case-003 | object-tag-dropped | `fromV1({ object: "project", id: "p1" })` | `{ id: "p1" }` |
| v1-case-004 | object-tag-dropped, recursion-depth | `fromV1({ data: [{ object: "item", item_key: "K-1" }] })` | `{ data: [{ itemKey: "K-1" }] }` |
| v1-case-005 | opaque-keys | `fromV1({ counts: { in_progress: 3 } })` | `{ counts: { in_progress: 3 } }` (same keys, not `inProgress`) |
| v1-case-006 | opaque-keys | `fromV1({ config: { sort_by: "x" }, detail: { a_b: 1 }, body: { c_d: 2 }, value: { e_f: 3 } })` | Every nested key keeps its original casing |
| v1-case-007 | opaque-keys | `toV1Body({ config: { sortBy: "x" } })` | `{ config: { sortBy: "x" } }` |
| v1-case-008 | snakeize-rule | `toV1Body({ projectId: "p", createdAt: "x" })` | `{ project_id: "p", created_at: "x" }` |
| v1-case-009 | null-kept, undefined-dropped | `toV1Body({ dueDate: null, note: undefined })` | `{ due_date: null }` |
| v1-case-010 | object-key-kept-on-write | `toV1Body({ object: "x" })` | `{ object: "x" }` |
| v1-case-011 | timestamp-nonnumber-passthrough | `fromV1({ created: null })` | `{ created: null }` |
| v1-case-012 | timestamp-nonfinite-null | `fromV1({ created: NaN })` | `{ createdAt: null }` |
| v1-case-013 | scalar-passthrough | `fromV1(null)`, `fromV1("s")`, `toV1Body(undefined)` | `null`, `"s"`, `undefined` |
| v1-case-014 | array-recursion | `fromV1([{ a_b: 1 }, { c_d: 2 }])` | `[{ aB: 1 }, { cD: 2 }]` |
| v1-case-015 | mapper-pure | Call `toV1Body(x)` on an object `x` with a nested object | `x` is unchanged and the result is a distinct object |
| v1-case-016 | later-key-wins | `fromV1({ project_id: "a", projectId: "b" })` | `{ projectId: "b" }` |
| v1-case-017 | v1write-shape, v1write-no-headers | `v1Write("POST", { projectId: "p" })` | `{ method: "POST", body: "{\"project_id\":\"p\"}" }` with no `headers` key |
| v1-case-018 | v1write-shape | `v1Write("POST", undefined)` | `{ method: "POST", body: undefined }` |
| v1-case-019 | v1json-single | `authedJson` resolves `{ project_id: "x", created: 0 }` | `v1Json(url)` resolves `{ projectId: "x", createdAt: "1970-01-01T00:00:00.000Z" }` |
| v1-case-020 | v1json-errors-propagate | `authedJson` rejects with a 404 error | `v1Json(url)` rejects with that same error object |
| v1-case-021 | v1list-all-pages, v1list-cursor-on-wire-rows | Page one has `has_more` true and last row `id: "r2"`; page two has `has_more` false | `v1List` requests `starting_after=r2` on the second call and resolves all rows camelCased in one array |
| v1-case-022 | v1page-one-page, v1page-url-verbatim | `listV1Page` resolves `{ data: [{ a_b: 1 }], hasMore: true }` | `v1Page(url)` resolves `{ data: [{ aB: 1 }], hasMore: true }` and requested `url` unchanged |
| v1-case-023 | v1list-all-pages | Last row of a `has_more` page has no `id` | `v1List` rejects with the error thrown by `listAllV1` |
| v1-case-024 | fromv1-unchecked-cast | `fromV1<{ a: number }>({ b: "x" })` | Returns `{ b: "x" }` with no error |

## Edge Cases

- **Null and empty input** (MUST): `fromV1` and `toV1Body` of `null`, a primitive, or `undefined` return it unchanged; an empty object returns `{}`; an empty array returns `[]`. A page with a missing or non-array `data` is turned into `[]` by `listV1Page` before this module maps it.
- **Date, Map and class instances** (MUST): Any non-array object is traversed with `Object.entries`, so a `Date` or `Map` becomes `{}`. Callers pass plain JSON-shaped values.
- **Opaque map containing the type tag** (MUST): `object` is dropped only in the traversed part of a `/v1` response; inside an opaque value an `object` key is preserved because the value is not traversed.
- **Opaque name at any depth** (MUST): The five opaque names apply wherever they appear in a traversed object, so a nested property that merely happens to be called `value` or `body` is also left verbatim.
- **Null `created` or `updated`** (MUST): A `/v1` row with `created: null` is emitted with `created: null` and no `createdAt`; only numbers are converted.
- **Non-finite timestamp** (MUST): `created: NaN` or `Infinity` yields `createdAt: null`.
- **Key collisions** (MUST): Colliding renames, such as `project_id` plus `projectId`, or numeric `created` plus an existing `createdAt`, keep the later key's value silently. Nothing is logged or thrown.
- **Unusual keys** (MUST): A leading underscore (`_id`) camelizes to `Id`; `a__b` to `a_B`; `a_1` to `a1`. Snakeizing `projectID` gives `project_i_d`; a leading capital (`Foo`) gives `_foo`. These follow directly from the two regexes.
- **Reference sharing** (MUST): Opaque values and primitive values are returned by reference or copy as-is; mutating an opaque value in the output mutates the input's.
- **Cyclic input** (MUST NOT be relied on): The mappers have no cycle guard, so a cyclic structure recurses until the engine's stack limit throws a `RangeError`. `/v1` JSON cannot be cyclic.
- **Write with no body** (MUST): `v1Write("POST", undefined)` yields `body: undefined`, so no request body is sent.
- **Error states** (MUST): A non-ok HTTP status, a refresh failure, or a `204 No Content` reply to `v1Json` is thrown by the request layer and reaches the caller unmapped. `v1List` also rejects when a `has_more` page ends on a row with no id, rather than returning a truncated list.
- **Offline or unreachable server** (MUST): The underlying `fetch` rejection propagates unchanged from every wrapper; nothing here retries or queues.
- **Mid-pagination failure** (MUST): If any page of `v1List` fails, the whole call rejects and the pages already fetched are discarded.
- **Concurrent access** (MUST): Every function is stateless, so concurrent calls do not interact. In `v1List`, pages are fetched one at a time.
- **Cancellation and timeout** (MAY be added by a port): The source passes no `AbortSignal` and sets no timeout; `v1List` cannot be aborted between pages.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `OPAQUE` | set of key names | `config`, `detail`, `body`, `value`, `counts` | Property names whose values are copied verbatim by both mappers. Module-private constant, not caller-configurable. |
| `url` | string | none | The `/v1` endpoint or collection url passed to `v1Json`, `v1List` and `v1Page`. |
| `init` | `RequestInit` | none | Optional request init for `v1Json`; forwarded to `authedJson`. `v1List` and `v1Page` take no init. |
| `method` | `"POST"` | none | Method recorded by `v1Write`; no other method is accepted by its type. |
| Request layer | injected import | `authedJson`, `listAllV1`, `listV1Page`, `unixToIso` from the data package's `http` module | Supplies the authentication, paging (`limit=100`, `starting_after`), and timestamp conversion. A port supplies equivalents. |

## Deep Linking

Not applicable: the module maps JSON values and wraps requests; it has no routes or URLs of its own.

## Localization

Not applicable: the module defines no user-facing strings; error messages come from the request layer it calls, and the one message it can surface through `listAllV1` is in that function, not here.

## Accessibility Options

Not applicable: the module has no display output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag or setting.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the module stores nothing and handles no token or credential itself. Request bodies pass through `JSON.stringify` and the request layer, which attaches the bearer token. Token storage and transmission are the auth client's concern.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: Port the two mappers as functions over a decoded JSON tree (`Any` or a `JSONValue` enum) rather than relying on `JSONDecoder.keyDecodingStrategy`, because `.convertFromSnakeCase` has no opaque-key exemption and does not drop the `object` tag or convert `created` to a `Date`. Use `URLSession` with `async`/`await`, which gives a `Sendable` pure mapper for free; model `null` versus absent with an explicit optional-of-optional or a `JSONValue.null` case so null-clears-a-column survives.
- **Compose**: Use `kotlinx.serialization.json` `JsonElement` for the tree walk, since the mapper needs to skip opaque subtrees and rename keys, which typed key naming strategies cannot do per property. A `JsonNull` stays `JsonNull`; an absent key is simply not added. Run fetches on `Dispatchers.IO` through an OkHttp or Ktor client and map in the suspend function.
- **React/Web**: This is the source platform. The implementation is `packages/web/packages/data/src/v1-case.ts`, re-exporting nothing and importing `authedJson`, `listAllV1`, `listV1Page` and `unixToIso` from `./http`, which re-exports the auth package's client. Behavior specific to it: the `undefined` skip relies on JavaScript's distinct `undefined`, mapping is by `Object.entries`, and recursion is on the plain object tree that `res.json()` returns.
- **AppKit / UIKit**: Same approach as SwiftUI: `JSONSerialization` yields `[String: Any]` with `NSNull` for null, so keep `NSNull` and drop only keys that were never set. Map on a background queue or in an `async` function, and hand the camelCase result to view code on the main actor. `Date` conversion from unix seconds is `Date(timeIntervalSince1970:)`, with `ISO8601DateFormatter` when an ISO string is required.
- **WinUI 3**: Use `System.Text.Json` with `JsonNode` (`JsonObject`, `JsonArray`, `JsonValue`) for the recursive walk; do not use `JsonNamingPolicy.SnakeCaseLower`, because it cannot skip opaque properties, drop `object`, or turn `created` into `createdAt`. Build a new `JsonObject` per object and deep-clone opaque nodes with `DeepClone()` if the output must not alias the input (the TypeScript source aliases them). `JsonNode` distinguishes a JSON null (a null node) from a missing property, which matches the null-kept and undefined-dropped rules; represent `undefined` in a typed body with `JsonIgnoreCondition.WhenWritingNull` turned off and an explicit omitted flag. Convert timestamps with `DateTimeOffset.FromUnixTimeSeconds(n).UtcDateTime.ToString("O")` and guard non-finite doubles with `double.IsFinite` to emit null. Wrap the fetches in `HttpClient` with `async Task<T>` methods; `v1Page` returns a record such as `(IReadOnlyList<T> Data, bool HasMore)`, and a `v1List` equivalent loops sequentially passing `starting_after` and `limit=100`. Pass a `CancellationToken` through, which the source does not.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/v1-case.ts` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Camelize idempotently instead of converting only snake_case input.
**Rationale**: The source header states the gateway renames only properties the legacy spec declares, so an undeclared property already arrives in camelCase (`itemKey`, `projectName`). Applying the regex to it is a no-op, so both shapes land on one key.
**Approved**: pending

**Decision**: Treat `config`, `detail`, `body`, `value` and `counts` as opaque by key name at every depth.
**Rationale**: The header comment lists these as free-form maps whose keys must keep the casing they were stored with, with `counts` keyed by category names such as `in_progress`. The cost, which a port must keep, is that any other property that happens to use one of these names is also left verbatim.
**Approved**: pending

**Decision**: Drop the `object` key on read only, and convert only numeric `created` and `updated`.
**Rationale**: `object` is the `/v1` type tag, not data (a source comment). Converting only numbers means a `null` or absent timestamp stays under its `/v1` name rather than becoming a camelCase `null`. A row that really has a field called `object` loses it on read.
**Approved**: pending

**Decision**: Silently overwrite on key collisions and skip cycle detection.
**Rationale**: The source has no guard for either; wire JSON cannot be cyclic and collisions only arise from a gateway echoing both forms. The recipe records the behavior so a port matches it.
**Approved**: pending

**Decision**: Keep `v1Write` to `POST` with no headers, and keep `v1List` on `listAllV1` defaults.
**Rationale**: The wrappers are deliberately thin. `Content-Type` is added by the request layer when a body exists, and paging, retry on 401 and error construction stay in the auth package so they are not reimplemented here.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |

The module separates concerns cleanly: pure key mapping is split from the thin fetch wrappers, and authentication, paging and HTTP errors live in the auth client it imports. Unit-test coverage passes: `src/__tests__/v1-case.test.ts` asserts every conformance vector (v1-case-001 to v1-case-024) directly, and the projects client tests exercise the same mappers indirectly. Pagination support and API conventions pass because `v1List` and `v1Page` map `/v1` lists and `has_more` correctly. Error handling is partial: errors from the request layer propagate unchanged, but the mappers silently resolve key collisions and drop a legitimate `object` field. Timeout configuration fails because the wrappers set no timeout and take no abort signal for `v1List` or `v1Page`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (v1-case.test.ts, 24 of 24 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
