---
id: 7add8e4b-922e-4518-aa45-79bf56cdf8bc
title: "API Toolkit"
type: ingredient
version: 1.2.0
status: review
language: en
created: 2026-09-23
modified: 2026-11-22
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Same-origin request building, endpoint lookup and matching, schema-derived examples, and generic-CRUD headless logic for API browsing and data-table editing."
platforms:
  - typescript
  - web
tags:
  - crud
  - api
  - metadata
  - headless
depends-on: []
related:
  - ec64b22b-8a25-431d-8866-b7a01acd91fe
  - 3dc693ab-28e4-4624-9b2d-8dc81f81e037
references: []
approved-by: ""
approved-date: ""
---

# API Toolkit

## Overview

This recipe is the headless, non-visual logic shared by two sibling web packages: `@adh-sdk/api-explorer` (an API-exploration browser and a crawlable API reference) and `@adh-sdk/crud` (a generic data-table editor). Neither package exports a unit named after this recipe. It is the umbrella specification for their pure logic and headless state, so that the request-building, endpoint-lookup, schema-derivation, slugging, snippet, and generic-CRUD contracts are written down once instead of being re-derived by every UI recipe that consumes them.

The API-exploration half builds and executes same-origin backend-for-frontend (BFF) requests from generated endpoint metadata (`EndpointMeta`, projected from the backend OpenAPI spec into `API_ENDPOINTS` and `API_SCHEMAS`). It looks endpoints up by key, tag, and route shape, derives cycle-safe examples, type labels, and field lists from JSON Schema, highlights code with a lazily created dual-theme highlighter, projects endpoints to collision-checked URL slugs, generates cURL and JavaScript snippets with a fixed token placeholder, and maps HTTP method and status to presentation classes. A server entry point (`server.ts`) re-exports the non-interactive pieces without a client marker.

The CRUD half derives per-column editability from a fixed precedence, tracks staged and dirty row edits, gates table visibility and writability by a presentation-only exposure tier, exposes the set of schemas generic CRUD serves, defines the shared metadata shapes (`CrudTableMeta`, `CrudColumn`, `CrudRow`), runs list, create, update, and remove through the same `/api` BFF layer in a headless hook (`useCrudResource`), bridges an imperative unsaved-changes guard into a stable proxy (`useExitGuardChannel`), and reports the viewer's admin capability and readiness (`useViewer`).

## Behavioral Requirements

### Request Building and Execution

- **request-base**: The `API_BASE` constant MUST be the string `/api`.
- **request-same-origin**: A request produced by `buildRequest` MUST have a `url` that begins with `API_BASE`, never an absolute cross-origin URL.
- **path-substitution-encoded**: `substitutePath` MUST replace each `{name}` placeholder with the `encodeURIComponent` of the matching entry in `pathValues`.
- **path-substitution-unfilled**: `substitutePath` MUST leave a placeholder as the literal text `{name}`, unencoded, when its value is missing, `null`, or the empty string.
- **query-from-declared-params**: `buildRequest` MUST add a query pair only for each entry of `meta.params` whose `in` is `query` and whose value in `queryValues` is neither missing nor the empty string.
- **query-omitted-when-empty**: `buildRequest` MUST append no `?` to the url when no query pair was added.
- **body-allowed**: `bodyAllowed` MUST return true if and only if `meta.requestBody` is not `null` or `undefined`.
- **body-attached**: `buildRequest` MUST attach `values.body` as `body` only when the endpoint allows a body and `values.body` is neither missing nor blank after trimming.
- **body-untrimmed**: `buildRequest` MUST pass `values.body` through without trimming it.
- **content-type-header**: `buildRequest` MUST set `Content-Type` only when a body is attached, to `meta.requestBody.contentType`, defaulting to `application/json` when that value is absent.
- **authorization-header**: `buildRequest` MUST set `Authorization: Bearer <token>` only when `token` is truthy.
- **built-request-method**: `buildRequest` MUST copy `meta.method` unchanged into `method`.
- **mutating-methods**: `isMutating` MUST return false for exactly `GET`, `HEAD`, and `OPTIONS`, and true for every other string, compared case-sensitively.
- **response-normalization**: `executeRequest` MUST resolve to an `ApiResult` carrying `status`, `statusText`, `ok`, `headers`, `contentType`, `bodyText`, and `durationMs` for any HTTP status, and MUST NOT reject on a non-2xx status.
- **result-headers-and-type**: `executeRequest` MUST return `headers` as an array of name and value pairs and `contentType` as the `content-type` response header, or `null` when absent.
- **result-duration**: `executeRequest` MUST set `durationMs` to the elapsed time rounded to whole milliseconds.
- **network-failure-propagation**: `executeRequest` MUST let a transport-level failure (offline, DNS failure, a cross-origin block) reject its promise rather than resolve to an `ApiResult`. The endpoint detail view that calls it catches the rejection and shows the message, falling back to `Request failed`.
- **request-timeout**: `buildRequest` and `executeRequest` MUST NOT attach a timeout or an abort signal to the request; a request that never resolves stays in flight until the browser gives up.

### Endpoint Lookup and Matching

- **endpoint-key**: `endpointKey` MUST return a string reference unchanged and MUST return the upper-cased method, a space, and the path for an `EndpointRef`.
- **get-endpoint**: `getEndpoint` MUST return the `API_ENDPOINTS` entry for the key of its argument, or `undefined` when there is none.
- **index-lazy-cached**: The tag index, the tag list, and the path-shape index MUST each be built on first use and reused on every later call.
- **untagged-bucket**: An endpoint whose `tag` is absent MUST be listed under the tag `other`.
- **tag-ordering**: `allTags` MUST return the tags sorted with the default string sort.
- **endpoints-for-tag-ordering**: `endpointsForTag` MUST return a tag's endpoints sorted by path with `localeCompare`, then by method rank `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, with any other method ranked after them.
- **endpoints-for-unknown-tag**: `endpointsForTag` MUST return an empty array for a tag that has no endpoints.
- **shape-matching**: `matchEndpoints` MUST compare routes by path shape, treating every `{placeholder}` as equal whatever its name, so `{ecosystem id}` matches `{ecosystemId}`.
- **match-with-method**: `matchEndpoints` MUST return only the endpoint on the matching shape whose method equals the match's method, compared upper-cased.
- **match-without-method**: `matchEndpoints` MUST return every endpoint on the matching shape, in method rank order, when the match carries no method.
- **match-order-and-dedup**: `matchEndpoints` MUST return endpoints in the order the matches name them, each endpoint once.
- **match-miss-skipped**: `matchEndpoints` MUST leave out a match for which the spec has no endpoint.

### Code Highlighting

- **highlight-lazy-load**: The highlighting library MUST be loaded by dynamic import on the first `highlightToHtml` call, not at module load.
- **highlighter-singleton**: The highlighter promise MUST be created at most once while it has not rejected, and every later call MUST reuse it.
- **highlighter-themes-and-langs**: The highlighter MUST be created with the themes `github-light` and `github-dark` and the languages `json`, `bash`, and `javascript`.
- **highlight-output-variables**: `highlightToHtml` MUST emit both themes as CSS variables, with no default color, so the host theme selects the variant without re-highlighting.
- **highlighter-failure-recovery**: A rejected highlighter creation MUST reset the cache to empty so the next call retries, and the rejection MUST propagate to the caller of that call.
- **pretty-json-format**: `prettyJson` MUST return the parsed text re-serialized with two-space indentation and `lang` `json` when the trimmed input parses as JSON.
- **pretty-json-fallback**: `prettyJson` MUST return the original input text, untrimmed, with `lang` `json` when parsing fails, and MUST NOT throw.
- **pretty-json-blank**: `prettyJson` MUST return empty text with `lang` `json` for input that is empty or only whitespace.

### Schema-Derived Examples and Field Descriptions

- **ref-resolution-scope**: `refName` MUST return a name only for a `$ref` string that begins with `#/components/schemas/`, and `undefined` for any other value or for a non-object schema.
- **example-cycle-safety**: `schemaToExample` MUST carry a `seen` set of schema names through each reference step so a schema that refers to itself terminates, returning `null` at the repeated reference.
- **example-boolean-schemas**: `schemaToExample` MUST return `{}` for an undefined schema or `true`, and `null` for `false`.
- **example-precedence**: `schemaToExample` MUST try, in order, reference resolution, `anyOf` or `oneOf` selection, `allOf` merge, `example`, `default`, the first `enum` value, then a type-driven default, and stop at the first that applies.
- **example-union-choice**: `schemaToExample` MUST choose the first non-null variant of an `anyOf` or `oneOf`, or the first variant when every variant is null.
- **example-allof-merge**: `schemaToExample` MUST merge the object examples of the `allOf` parts into one object and ignore a part that does not yield a plain object.
- **example-type-defaults**: `schemaToExample` MUST return `2020-01-01T00:00:00.000Z` for a string of format `date-time`, `string` for any other string, `0` for an integer or number, `true` for a boolean, `null` for a null type, a one-element array of the item example for an array with `items`, and `[]` for an array without.
- **example-object-fallback**: `schemaToExample` MUST return an object of each property's example when the schema has `properties` and no recognized type, and `{}` otherwise.
- **type-label-forms**: `typeLabel` MUST return `any` for an undefined schema or `true`, `never` for `false`, the schema name for a `$ref`, `T[]` for an array of `T`, the schema `title` or `object` for an object, and the primary type otherwise, or `any` when the schema declares no type.
- **type-label-nullable**: `typeLabel` MUST append `?` for a nullable type, whether the nullability comes from a `null` union variant, a `type` array containing `null`, or `nullable: true`.
- **type-label-union**: `typeLabel` MUST join the labels of multiple non-null variants with ` | `.
- **type-label-enum-truncation**: `typeLabel` MUST list an enum of four or fewer values, each rendered as its JSON text (a string keeps its quotes) and joined by ` | `, and for more than four MUST list the first three followed by `| …`.
- **unwrap-to-object**: `unwrapToObject` MUST dereference a reference, unwrap array `items`, select the first non-null union variant, and merge `allOf` properties and `required` lists, returning `undefined` when no object results or a reference repeats.
- **field-description-depth**: `describeFields` MUST return one `SchemaField` per top-level property of the unwrapped object, with `name`, `type` from `typeLabel`, `required`, and `description` only when the property has a string description.
- **field-description-empty**: `describeFields` MUST return an empty array when the schema unwraps to no object or to an object without `properties`.

### Endpoint Slugging

- **slug-projection**: `endpointSlug` MUST split the path on `/`, drop empty segments, strip the braces from each `{param}` segment, and append the lower-cased method as the final segment.
- **slug-index-lazy**: The slug-to-key index MUST be built on first use of `endpointForSlug`.
- **slug-collision-detection**: Building the slug index MUST throw an `Error` whose message names the slug and both colliding keys when two distinct endpoints project to the same slug.
- **slug-lookup**: `endpointForSlug` MUST join the segments with `/` and return the matching endpoint, or `undefined` on a miss; a miss itself raises no error.
- **all-endpoints**: `allEndpoints` MUST return every `API_ENDPOINTS` value in the object's own key order.

### Snippet Generation

- **snippet-token-placeholder**: Every generated snippet MUST carry the literal `YOUR_TOKEN` as its bearer token and MUST NOT embed a caller-supplied token.
- **snippet-origin**: A snippet url MUST use the backend-native path, with no `/api` prefix, under the `origin` argument, which defaults to `https://api.agenticdeveloperhub.com`.
- **snippet-url-composition**: A snippet url MUST use the same placeholder substitution and the same query rules as `buildRequest`.
- **snippet-body-inclusion**: A snippet MUST include a body only when the endpoint declares a request body and the supplied body is non-empty after trimming, and it MUST include the trimmed body.
- **snippet-content-type**: A snippet with a body MUST carry a `Content-Type` of `meta.requestBody.contentType`, defaulting to `application/json`.
- **curl-snippet-escaping**: `curlSnippet` MUST wrap the body in single quotes and MUST replace each embedded single quote with the four-character sequence single quote, backslash, single quote, single quote.
- **javascript-snippet-body**: `javascriptSnippet` MUST emit the body as a `JSON.stringify` of the body text.
- **snippet-dispatch**: `snippetFor` MUST return the cURL snippet for `curl` and the JavaScript snippet for any other value.
- **snippet-languages**: `SNIPPET_LANGS` MUST list `curl` (label `cURL`, highlighted as `bash`) and `javascript` (label `JavaScript`, highlighted as `javascript`).

### Method and Status Tone Mapping

- **method-tone-mapping**: `methodBadgeClass` and `methodDotClass` MUST map each of `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` to its fixed classes, with `PUT` and `PATCH` sharing the orange tone.
- **method-tone-fallback**: `methodBadgeClass` MUST return `text-apt-text-muted border-apt-border` and `methodDotClass` MUST return `bg-apt-text-dim` for any other method, and the lookup MUST be case-sensitive.
- **method-text-class-consistency**: `methodTextClass` MUST return the first space-delimited token of `methodBadgeClass` for the same method.
- **status-tone-mapping**: `statusTone` MUST parse its string argument as a number and return `text-apt-green` for 200 to 299, `text-apt-orange` for 400 to 499, `text-apt-red` for 500 and above, and `text-apt-text-muted` otherwise, including a non-numeric status.

### Entry Points

- **server-entry-no-client-marker**: `server.ts` MUST NOT carry a `'use client'` directive.
- **server-entry-exports**: `server.ts` MUST re-export `ApiReferenceShell`, `endpointHref`, `ApiEndpointReference`, `StaticCodeBlock`, `endpointSlug`, `endpointForSlug`, `allEndpoints`, `allTags`, `endpointsForTag`, `getEndpoint`, `endpointKey`, `methodTextClass`, the types `EndpointMeta` and `EndpointRef`, and the props types `ApiReferenceShellProps`, `ApiEndpointReferenceProps`, and `StaticCodeBlockProps`.
- **shared-cache-via-package-path**: `server.ts` MUST import the tag, endpoint, and key functions from the package path `@adh-sdk/api-explorer/lib/getEndpoint`, not a relative path, so the server and client entry points share one module-level cache.
- **client-barrel-excludes-metadata**: The client-facing barrel `index.ts` MUST NOT re-export endpoint lookup or `API_ENDPOINTS`, so importing a client component does not bundle the generated metadata. The barrel `index.ts` carries `'use client'`, exports only the components (`ApiButton`, `ApiBrowser`, `ApiEndpointDetail`, `RecordApiButton`) and the `EndpointMeta` and `EndpointRef` types, and its own comment says keeping `getEndpoint` and `API_ENDPOINTS` off it stops the metadata entering the host page's initial bundle.

### Column Editability

- **server-managed-lock**: `isColumnEditable` MUST return false for a column with `serverManaged` true, in every mode and regardless of any override.
- **override-precedence**: `isColumnEditable` MUST return the `EDITABLE_OVERRIDES` value for `meta.key` and the column name when one exists and the column is not relational, ahead of the create-only default.
- **override-not-relational**: An override MUST NOT change the result for a relational column.
- **relational-column**: `isRelationalColumn` MUST return true for a column named in `meta.pkParams`, a column named `id`, `rdid`, `owner_id`, `author_id`, `customer_id`, `account_id`, or `user_id`, and a column whose name ends in `_id` or `_rdid`.
- **relational-create-only**: `isColumnEditable` MUST return true for a relational column in `create` mode and false in `edit` mode.
- **create-only-lock-on-edit**: `isColumnEditable` MUST return false for a column with `createOnly` true in `edit` mode.
- **default-editable**: `isColumnEditable` MUST return true for any other column in either mode.
- **hidden-columns**: `isColumnHidden` MUST return true if and only if `serverManaged` is true.
- **overrides-default-empty**: `EDITABLE_OVERRIDES` MUST be empty by default.

### Row Edit Tracking

- **dirty-detection**: `isRowDirty` MUST return true if and only if some key in the edit set has a value strictly unequal (`!==`) to the baseline value of that key, and MUST return false when the edit set is `undefined`.
- **dirty-ignores-absent-keys**: `isRowDirty` MUST NOT inspect baseline keys that are absent from the edit set.
- **draft-merge-immutability**: `mergeDraft` MUST return a new object with the edits laid over the baseline, and MUST NOT mutate either input.
- **draft-merge-no-edits**: `mergeDraft` MUST return a copy of the baseline when the edit set is `undefined`.

### Table Visibility Gate

- **presentation-only-gate**: `canReadTable`, `canWriteTable`, and `readableTables` MUST be treated as presentation only; the server re-checks every request.
- **read-allowlist**: `canReadTable` MUST return true for `owner` and `catalog` exposure for any viewer, and for every other value only when `isAdminViewer` is true.
- **write-allowlist**: `canWriteTable` MUST return true for `owner` exposure for any viewer, and for every other value only when `isAdminViewer` is true.
- **fail-closed-on-unknown-tier**: `canReadTable` and `canWriteTable` MUST return false for a non-admin viewer when `exposure` is absent or not one of `owner`, `catalog`, or `admin`.
- **order-preserving-filter**: `readableTables` MUST return the tables `canReadTable` accepts, in input order.

### Schema Allowlist

- **schema-allowlist-single-source**: `CRUD_SCHEMAS` MUST be a read-only set of the distinct `schema` values of `CRUD_TABLES`, computed once at module load.

### CRUD Resource State

- **item-url-substitution**: `itemUrl` MUST replace each `{param}` of `meta.itemPath` with the `encodeURIComponent` of the row's value for that primary-key name, using the empty string for a missing value, and MUST prefix the result with `/api`.
- **row-key-derivation**: `rowKey` MUST join the encoded primary-key values with `/` and MUST return the empty string for a single-key row with no value.
- **list-url-composition**: `listUrl` MUST return `/api` plus `meta.basePath`, followed by `?` and the `ecosystem_id` pair then the filter pairs, joined by `&`, when either is present.
- **list-url-no-query**: `listUrl` MUST append no `?` when there is no ecosystem scope and the filter is absent or empty.
- **loading-vs-fetching**: `loading` MUST be true only while a list call is open and no list has landed for the current list URL, and `fetching` MUST be true while any list call is open; a re-list of an already-loaded list MUST report `fetching` true and `loading` false.
- **list-on-mount**: `useCrudResource` MUST issue a list call on mount and again whenever `meta` or the list URL changes.
- **list-walks-collection**: A list call MUST fetch every row through `listAllV1` with the list URL.
- **out-of-order-response-guard**: `useCrudResource` MUST increment a sequence number per list call and MUST discard the rows, the error, and the fetching reset of any call that is not the latest.
- **list-error-state**: A failed latest list call MUST set `error` to `errorMessage(err)` and leave `rows` as they were; a started list call MUST clear `error`.
- **write-scope-query**: Every create, update, and remove url MUST carry `ecosystem_id` then `workspace` when present, where `workspace` is taken from `filter.workspace` and `ecosystem_id` from `scopeEcosystemId`, each URL-encoded.
- **create-update-method**: `createRow` MUST send a JSON `POST` to `meta.basePath` and `updateRow` MUST send a JSON `POST` to the item url, each with `JSON.stringify(values)` as the body.
- **remove-method**: `removeRow` MUST send `DELETE` to the item url through `authedJson` and MUST NOT read the `{id, object, deleted: true}` tombstone the backend answers with; `authedJson` throws on a 204 answer, which would reject the call.
- **mutation-relist**: `create`, `update`, and `remove` MUST call `refresh` after the matching raw mutator succeeds, and the raw mutators `createRow`, `updateRow`, and `removeRow` MUST NOT re-list.
- **mutation-error-not-hook-state**: A failed mutation MUST reject its promise to the caller and MUST NOT write to `error`, and a failed mutation MUST NOT trigger a re-list.

### Exit Guard Channel

- **stable-proxy-identity**: `useExitGuardChannel` MUST build the proxy once and return the same object identity for the life of the hook.
- **presence-is-the-dirty-signal**: `exitGuard` MUST be the proxy while a guard is registered and `null` after `registerGuard(null)`.
- **proxy-reads-latest-guard**: The proxy's `isDirty` MUST call the most recently registered guard's `isDirty`, and MUST return false when no guard is registered.
- **registrar-bails-out**: `registerGuard` MUST set only a presence boolean, so re-registering every render causes no extra render.

### Viewer State

- **standalone-default**: `useViewer` MUST return `isAdmin` false, `ready` true, and `principal` `null` when no auth provider is present.
- **admin-derivation**: With a provider, `useViewer` MUST return `isAdmin` from `isAdmin(auth.user)`, `ready` as the negation of `auth.isLoading`, and `principal` as `auth.user?.id ?? null`.

## Appearance

Not applicable: this is headless request-building, endpoint-lookup, schema-derivation, and generic-CRUD logic, not a visual component. The only visual data it holds is the class strings returned by the tone helpers.

## States

Not applicable: this is headless request-building, endpoint-lookup, schema-derivation, and generic-CRUD logic, not a visual component. Runtime state (loading and fetching in `useCrudResource`, guard presence in `useExitGuardChannel`, `ready` and `isAdmin` in `useViewer`) is specified under Behavioral Requirements.

## Accessibility

Not applicable: this is headless request-building, endpoint-lookup, schema-derivation, and generic-CRUD logic, not a visual component. It renders no element and handles no focus or input.

## Conformance Test Vectors

Test names refer to `packages/web/packages/api-explorer/src/__tests__/conformanceVectors.test.ts` (api-explorer), `packages/web/packages/crud/src/__tests__/conformanceVectors.test.tsx` (crud), `matchEndpoints.test.ts`, and `useCrudResource.test.tsx`. Rows without a named test are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| api-toolkit-001 | method-text-class-consistency, method-tone-mapping | `methodTextClass` for GET, POST, PUT, PATCH, DELETE | Equals the first token of `methodBadgeClass` for each (conformance test vector 1) |
| api-toolkit-002 | method-tone-fallback | `methodDotClass('TRACE')` | `bg-apt-text-dim` (conformance test vector 2) |
| api-toolkit-003 | read-allowlist | `canReadTable` on an `admin` table, non-admin viewer | `false` (conformance test vector 3) |
| api-toolkit-004 | write-allowlist | `canWriteTable` on a `catalog` table, non-admin viewer | `false` (conformance test vector 4) |
| api-toolkit-005 | override-not-relational, relational-create-only | Override set for a relational column, `edit` mode | `false` (conformance test vector 5) |
| api-toolkit-006 | dirty-detection | No edits, then an edit equal to the baseline value | `false` both times (conformance test vector 6) |
| api-toolkit-007 | remove-method, mutation-relist | `remove(row)` against a 200 tombstone | One `DELETE` through `authedJson`, resolves, then re-lists (conformance test vector 7) |
| api-toolkit-008 | out-of-order-response-guard | Two list calls, the older resolving last | Only the newer rows are written (conformance test vector 8) |
| api-toolkit-009 | slug-projection | `endpointSlug` for `GET /users/{id}` | `['users', 'id', 'get']` (conformance test vector 9) |
| api-toolkit-010 | authorization-header | `buildRequest` without then with a token | No `Authorization` header, then `Bearer <token>` (conformance test vector 10) |
| api-toolkit-011 | request-base, request-same-origin | `buildRequest` for `/v1/personas/{id}` with `id` `a b` | `url` is `/api/v1/personas/a%20b` |
| api-toolkit-012 | path-substitution-unfilled | `substitutePath('/v1/x/{id}', {id: ''})` | `/v1/x/{id}` |
| api-toolkit-013 | query-from-declared-params, query-omitted-when-empty | Query param `q` set to `''`, then to `x` | No `?`, then `?q=x` |
| api-toolkit-014 | body-allowed, body-attached, content-type-header | Endpoint with no `requestBody` and body text `{}`, then with a body of type `text/plain` and body text `   ` | No body and no `Content-Type`; no body and no `Content-Type` |
| api-toolkit-015 | content-type-header, body-untrimmed | Endpoint with a body and no `contentType`, body text ` {"a":1} ` | `Content-Type: application/json`, body ` {"a":1} ` unchanged |
| api-toolkit-016 | mutating-methods | `isMutating` for `GET`, `HEAD`, `OPTIONS`, `POST`, `get` | `false`, `false`, `false`, `true`, `true` |
| api-toolkit-017 | response-normalization, result-duration | `fetch` resolves a 404 with body `nope` | Resolves `status` 404, `ok` false, `bodyText` `nope`, integer `durationMs` |
| api-toolkit-018 | network-failure-propagation, request-timeout | `fetch` rejects with a `TypeError` | `executeRequest` rejects with that error; no timeout or signal was passed to `fetch` |
| api-toolkit-019 | match-order-and-dedup, match-without-method, shape-matching, match-miss-skipped | Matches named in `matchEndpoints.test.ts` (placeholder names differ, no method, repeats, a missing route) | Endpoints on the shape in method order, each once, the missing route omitted |
| api-toolkit-020 | endpoint-key, get-endpoint | `endpointKey({method: 'get', path: '/v1/a'})`, then `getEndpoint('POST /missing')` | `GET /v1/a`, then `undefined` |
| api-toolkit-021 | untagged-bucket, endpoints-for-tag-ordering, tag-ordering | Endpoints with no `tag`, and two methods on one path | Listed under `other`; the collection path sorts first, GET before POST |
| api-toolkit-022 | pretty-json-format, pretty-json-fallback, pretty-json-blank | `prettyJson` of `{"a":1}`, `not json`, and `   ` | Indented two spaces, `not json` unchanged, empty text, always `lang` `json` |
| api-toolkit-023 | highlighter-failure-recovery | The dynamic import rejects once, then succeeds | The first call rejects; the next call retries and resolves |
| api-toolkit-024 | example-cycle-safety | Schema `A` with a property referring to `A` | Finite example; the repeated reference yields `null` |
| api-toolkit-025 | example-precedence, example-type-defaults | `{type:'string', format:'date-time'}`, `{type:'integer', default: 5}`, `{enum:['x','y']}` | `2020-01-01T00:00:00.000Z`, `5`, `x` |
| api-toolkit-026 | type-label-nullable, type-label-union, type-label-enum-truncation | `{type:['string','null']}`, a five-value enum | `string?`; the first three values then `| …` |
| api-toolkit-027 | field-description-depth, unwrap-to-object | Array response of a `$ref` object with one required and one optional property | One row per property with `required` true and false, no nested fields |
| api-toolkit-028 | slug-collision-detection | Two endpoints that project to one slug | `endpointForSlug` throws `api-explorer: endpoint slug collision on "<slug>"` |
| api-toolkit-029 | slug-lookup | `endpointForSlug(['no','such','get'])` | `undefined` |
| api-toolkit-030 | snippet-token-placeholder, snippet-origin | `curlSnippet` for `GET /v1/a` | `curl -X GET "https://api.agenticdeveloperhub.com/v1/a" \` then `  -H "Authorization: Bearer YOUR_TOKEN"` |
| api-toolkit-031 | curl-snippet-escaping, snippet-body-inclusion | Body `{"n":"it's"}` | The body line ends `-d '{"n":"it'\''s"}'` |
| api-toolkit-032 | status-tone-mapping | `statusTone` for `204`, `404`, `503`, `302`, `default` | green, orange, red, muted, muted |
| api-toolkit-033 | server-managed-lock, create-only-lock-on-edit, default-editable | Server-managed column in `create`; create-only column in `edit`; plain column in `edit` | `false`; `false`; `true` |
| api-toolkit-034 | relational-column | Columns `owner_id`, `external_rdid`, `slug` on a table whose `pkParams` is `['slug']` | All three relational |
| api-toolkit-035 | fail-closed-on-unknown-tier, order-preserving-filter | A table with no `exposure`, non-admin viewer, in `readableTables` | Denied read and write; the retained tables keep input order |
| api-toolkit-036 | item-url-substitution, row-key-derivation | `pkParams` `['a','b']`, row `{a: 'x/y', b: 1}` | `itemUrl` ends `x%2Fy` then `1`; `rowKey` is `x%2Fy/1` |
| api-toolkit-037 | list-url-composition | Filter `{source_provider: 'reddit'}` and scope `eco-1` | `/api/v1/billing/offers?ecosystem_id=eco-1&source_provider=reddit` (`useCrudResource.test.tsx`) |
| api-toolkit-038 | write-scope-query | Filter `{workspace: 'acme co'}` and scope `eco-1`, then an update | `?ecosystem_id=eco-1&workspace=acme%20co` on create, update, and delete (`useCrudResource.test.tsx`, workspace on every write) |
| api-toolkit-039 | list-error-state, mutation-error-not-hook-state | `listAllV1` rejects; separately `authedJson` rejects on `create` | `error` holds the message; the `create` promise rejects, `error` is unchanged, and no re-list runs |
| api-toolkit-040 | loading-vs-fetching | Switch `meta` to a table not yet loaded, then call `refresh` on a loaded one | `loading` true with `fetching` true; `loading` false with `fetching` true |
| api-toolkit-041 | presence-is-the-dirty-signal, proxy-reads-latest-guard, stable-proxy-identity | Register a guard, then `registerGuard(null)` | `exitGuard` is the same proxy while present and its `isDirty` reads the latest guard; `null` afterward |
| api-toolkit-042 | standalone-default, admin-derivation | `useViewer` with no provider; with a loading provider whose user is an admin | `{isAdmin: false, ready: true, principal: null}`; `isAdmin` true, `ready` false |
| api-toolkit-043 | draft-merge-immutability, draft-merge-no-edits | `mergeDraft(base, {a: 2})` and `mergeDraft(base, undefined)` | New objects; `base` unchanged |

## Edge Cases

- **Unfilled path parameter** (MUST): `substitutePath` leaves `{name}` visible so the user sees what is missing rather than a silently wrong URL. `itemUrl` instead substitutes the empty string for a missing key value.
- **Empty and missing input** (MUST): `buildRequest` treats a missing or empty query value as absent; blank body text is treated as no body; `prettyJson` returns empty text for blank input; `describeFields` returns `[]` for a schema with no object shape; `endpointsForTag` returns `[]` for an unknown tag.
- **Cyclic schema** (MUST): `schemaToExample` and `unwrapToObject` carry a `seen` set and stop on a repeated reference, returning `null` and `undefined` respectively. `typeLabel` never recurses through a `$ref`, so it needs no guard.
- **External reference** (MUST): `refName` accepts only `#/components/schemas/` references, so any other `$ref` is not resolved and `schemaToExample` falls through to its remaining steps. A reference to a name missing from the schema map yields the default example for an undefined schema, `{}`.
- **Slug collision** (MUST): Building the slug index throws on a collision. The map is assigned before the loop, so after a throw a later `endpointForSlug` call finds the partly built index and does not throw again. This follows the code as written.
- **Boundary values** (MUST): An enum of exactly four values is listed in full and five is truncated; status 200 and 299 are green, 400 and 499 orange, 500 red, and 300 to 399 muted.
- **Method case** (MUST): `endpointKey` and `matchEndpoints` upper-case the method; `isMutating`, `methodBadgeClass`, and `methodDotClass` do not, so a lower-case method is treated as mutating and as an unknown method.
- **Network failure of a built request** (MUST): A transport failure rejects the promise from `executeRequest`; the endpoint detail view turns it into a message. Nothing in the toolkit retries.
- **Hung request** (MUST): No timeout or cancellation bounds a request; a connection that never resolves stays in flight.
- **Out-of-order list responses** (MUST): The sequence guard in `useCrudResource` discards a stale list response. A mutation has no sequence guard of its own; the re-list that follows it goes through the same list guard.
- **Failed refresh keeps stale rows** (SHOULD): A failed list call leaves `rows` unchanged. After a switch to a table whose first list fails, `rows` still hold the previous table's rows while `error` is set and `loading` is false. A failed background re-list shows its error beside the stale rows.
- **Composite-key table past one page** (MUST): `listAllV1` throws because the gateway pages by id; the message lands in `error` like any failed list. The paging itself is owned by `@adh-sdk/auth/client`.
- **Concurrent mutations** (MUST): Mutations are not serialized or de-duplicated by the hook; each call sends its own request, and the batch editor uses the raw mutators and refreshes once. JavaScript is single-threaded, so state updates cannot interleave inside one call.
- **Concurrent access to the editability overrides** (MUST): `EDITABLE_OVERRIDES` is a module-level object that is empty by default and populated by hand; production code does not mutate it at runtime, and single-threaded execution means no race.
- **Highlighter load failure** (MUST): A rejected import or creation rejects that call and clears the cache, so the next call retries; a session is not disabled by one transient chunk-load failure.
- **Unknown or missing exposure tier** (MUST): The gate denies read and write to a non-admin viewer, matching the server's fail-closed `hasPermission`.
- **Auth still bootstrapping** (MUST): `useViewer` reports `ready` false while `auth.isLoading` is true, so gates hold rather than guess; without a provider it reports a settled anonymous viewer.
- **Offline or disconnected state**: Not applicable beyond network failure above: the toolkit holds no connection, queue, or cache of responses, and `useCrudResource` surfaces a failed list as `error` and a failed write as a rejection.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `API_BASE` | string constant | `/api` | Same-origin BFF base for `buildRequest` and `useCrudResource`; the proxy strips `/api` and forwards to the unprefixed backend. Not configurable. |
| `token` (`buildRequest`) | `string` or `null` | none | Optional bearer token; sent as `Authorization: Bearer <token>` when truthy. The caller supplies it (from `useAuth`). |
| `values` (`buildRequest`) | `RequestValues` | required | `pathValues`, `queryValues`, and optional raw JSON `body` text. |
| `origin` (snippets) | `string` | `https://api.agenticdeveloperhub.com` (`PUBLIC_API_ORIGIN`) | Public origin used only for generated snippets. |
| `TOKEN_PLACEHOLDER` | string constant | `YOUR_TOKEN` | Token text embedded in snippets. |
| `API_ENDPOINTS`, `API_SCHEMAS` | generated constants | generated | Endpoint metadata and `components.schemas`, generated from the backend OpenAPI spec by `pnpm gen`. |
| `schemas` (schema helpers) | `ApiSchemas` | `API_SCHEMAS` | Resolution target for `$ref`; injectable for tests. |
| `EDITABLE_OVERRIDES` | `Record<string, Record<string, boolean>>` | `{}` | Per-table, per-column editability forcing for non-relational, non-server-managed columns. |
| `CRUD_TABLES` | generated constant | generated | Table descriptors emitted by `scripts/gen_table_metadata.py`; source of `CRUD_SCHEMAS`. |
| `meta` (`useCrudResource`) | `CrudTableMeta` | required | The table descriptor. |
| `filter` (`useCrudResource`) | `Record<string, string>` | none | Column-equality list filter; its `workspace` key also rides every write. |
| `scopeEcosystemId` (`useCrudResource`) | `string` | none | Ecosystem scope sent as `ecosystem_id` on every verb. |
| `isAdminViewer` (exposure checks) | `boolean` | required | Usually `useViewer().isAdmin`. |
| Auth context | optional provider | absent | `useViewer` reads it through `useOptionalAuth`. |
| Injected helpers | `authedJson`, `listAllV1`, `errorMessage` | n/a | Imported from `@adh-sdk/auth/client` and `@adh-sdk/ui/lib/errors`. |

## Deep Linking

`slug.ts` exists to give each endpoint a crawlable route: `endpointSlug` projects an endpoint to path segments with braces stripped plus the lower-cased method, `GET /persona/personas/{id}` becoming `persona/personas/id/get`, and `endpointForSlug` reverses it, returning `undefined` on a miss. `allEndpoints` enumerates the routes to prerender. No other given source defines a URL scheme.

## Localization

No given source externalizes strings. These hardcoded English strings are facts about the implementation, not gaps:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (inline) | `YOUR_TOKEN` | Token placeholder in every generated snippet |
| (inline) | `api-explorer: endpoint slug collision on "<slug>" (<key> vs <key>)` | Developer-facing error thrown by the slug index |
| (inline) | `string`, `any`, `never`, `object`, `other` | Type labels and the untagged-tag bucket |

Error text for a failed list comes from `errorMessage` in `@adh-sdk/ui`, and the `Request failed` fallback belongs to the endpoint detail view; neither is produced here.

## Accessibility Options

Not applicable: no given source renders a surface, so there is no motion, contrast, or color-differentiation behavior to define; the tone helpers return class names only.

## Feature Flags

Not applicable: no given source reads a feature flag; `EDITABLE_OVERRIDES` is column configuration, not a flag.

## Analytics

Not applicable: no given source emits an analytics event or calls an analytics client.

## Privacy

- **Data collected**: None. No given source records or reports user data.
- **Storage**: Nothing is written to local storage, a database, or any durable store. Module-level caches hold only generated metadata indexes and the highlighter.
- **Transmission**: `buildRequest` forwards the caller's token only as an `Authorization` header on a same-origin request; `useCrudResource` sends row values in the request body through `authedJson`. The token is not persisted or logged.
- **Retention**: None.
- Snippets use `YOUR_TOKEN` so copying one to the clipboard cannot leak a live credential.
- The exposure gate narrows what the UI offers; it is documented as not a security boundary, and `useViewer.principal` is exposed so per-viewer caches can be keyed by user.

## Logging

Not applicable: no given source calls a logger or writes diagnostic output.

## Platform Notes

- **SwiftUI**: Use `URLSession` with `URLRequest` for the request builder and executor and `async`/`await`; a non-2xx `HTTPURLResponse` does not throw, which matches `executeRequest`, while transport errors throw as `URLError`. Dynamic schema examples need `JSONSerialization` or `JSONValue`, because `Codable` is statically typed. Model `useCrudResource` as an `@Observable` or `ObservableObject` class with `rows`, `loading`, `fetching`, and `error`, and guard stale responses with a counter on a `@MainActor` type.
- **Compose**: Use OkHttp or Ktor for requests, `kotlinx.serialization.json.JsonElement` for schema walking, and a `ViewModel` exposing `StateFlow` for `rows`, `loading`, `fetching`, and `error`. Cancel superseded list calls with `Job.cancel` or `collectLatest`, or keep an `AtomicInteger` sequence to match the guard. Keep the exit guard in a `remember`ed holder with a stable lambda.
- **React/Web**: The source is `packages/web/packages/api-explorer/src/lib/*.ts`, `server.ts`, `types.ts`, and `packages/web/packages/crud/src/*.ts` with the two hooks. It uses `fetch`, `URLSearchParams`, `performance.now`, dynamic `import('shiki')`, and React `useState`, `useRef`, `useCallback`, `useMemo`, and `useEffect`. `server.ts` has no client marker, the CRUD hooks and `viewer.ts` carry `'use client'`, and the cache-sharing import goes through the package path.
- **AppKit / UIKit**: Use `URLSession` as above and a view-model or `NSObject` with Combine `@Published` properties or `AsyncStream` to drive a table or collection view. The unsaved-changes guard maps to a stable delegate or closure object consulted by `windowShouldClose` or `isModalInPresentation`. Apple has no `fetch`-style never-throws default, so wrap non-2xx responses explicitly as `ApiResult`.
- **WinUI 3**: Use `System.Net.Http.HttpClient` with `HttpRequestMessage`; `SendAsync` does not throw on a non-2xx status, matching `executeRequest`, and throws `HttpRequestException` on transport failure, matching its rejection. Set `HttpClient.Timeout` or pass a `CancellationToken`, which the source does not do. Build the query with `HttpUtility.ParseQueryString` or `Uri.EscapeDataString`, and parse schemas with `System.Text.Json.Nodes.JsonNode` for the example walk. Replace the hook with a view-model implementing `INotifyPropertyChanged` that exposes `ObservableCollection<CrudRow>` plus `Loading`, `Fetching`, and `Error`, guarding stale responses with an `Interlocked.Increment` sequence checked on the dispatcher thread (`DispatcherQueue.TryEnqueue`). Show the tone as `Brush` resources keyed by method, and bind `ReadOnly` or `IsEnabled` from the editability functions. Use a `ConditionalWeakTable` or a lazily initialized static dictionary for the module-level indexes, and `Windows.Storage` is not needed because nothing persists.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/api-explorer/src/lib/buildRequest.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/getEndpoint.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/highlight.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/schema.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/slug.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/snippets.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/lib/tone.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/server.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/api-explorer/src/types.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/editability.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/edits.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/exposure.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/schemas.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/types.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/useCrudResource.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/useExitGuardChannel.ts` | confirmed (1.2.0) |
| web | `packages/web/packages/crud/src/viewer.ts` | confirmed (1.2.0) |

## Design Decisions

### Client-side exposure gate is presentation-only

**Decision**: `canReadTable`, `canWriteTable`, and `readableTables` in `exposure.ts` filter what the UI offers and are never the authorization boundary, and they use allowlists that deny an unclassifiable tier.

**Rationale**: The server re-checks every request, and an allowlist fails closed the way the server's `hasPermission` does; a denylist would list every table the moment a meta arrived without a tier.

**Approved**: pending

### Deliberate duplication of the shiki singleton

**Decision**: `highlight.ts` keeps its own module-level `highlighterPromise` rather than sharing the one in `@adh-sdk/markdown`.

**Rationale**: The source comment states that markdown's highlighter lives inside a unified and rehype pipeline whose heavy dependencies this package does not want, and that sharing about 15 lines is not worth the coupling. The two theme lists must be kept in sync by hand.

**Approved**: pending

### Server-only and client-only entry points

**Decision**: `server.ts` carries no client marker and is kept apart from the client barrel, which omits endpoint lookup and the generated metadata.

**Rationale**: The server components keep server semantics, and a consumer that imports only an interactive component does not bundle the large generated endpoint map.

**Approved**: pending

### Package-path imports share module-level cache state

**Decision**: `server.ts` imports `allTags`, `endpointsForTag`, `getEndpoint`, and `endpointKey` from `@adh-sdk/api-explorer/lib/getEndpoint` rather than a relative path.

**Rationale**: The server entry and the client barrel are separate chunk graphs; one package path gives both the same module instance and the same cached `_byTag` and `_tags`.

**Approved**: pending

### Non-live token placeholder in generated snippets

**Decision**: Snippets always embed `YOUR_TOKEN` and the backend-native path against the public origin, never the live token or the `/api` path.

**Rationale**: A snippet is copied to a clipboard or a shared document, so a live token would be a leak; the caller replaces the placeholder before running it.

**Approved**: pending

### Executor never throws on a non-2xx status

**Decision**: `executeRequest` returns a normalized `ApiResult` for any status and lets only transport failures reject.

**Rationale**: Error bodies such as 401 and 404 render like successes in the explorer; the cost is that a caller must handle the rejection for network failures.

**Approved**: pending

### Editability precedence

**Decision**: Server-managed columns are never editable, overrides apply only to non-relational columns, relational keys are editable only on create, and create-only columns lock on edit.

**Rationale**: The source comments state that these classifications also drive visibility, so letting an override contradict them would render an input the payload builder then silently drops, and re-pointing a key on edit would orphan or corrupt data.

**Approved**: pending

### Workspace and ecosystem scope ride every write

**Decision**: `useCrudResource` sends `ecosystem_id` and `filter.workspace` on create, update, and delete, though other filter keys narrow only the list.

**Rationale**: The source comment records that a workspace sent on the list alone listed an org's rows and then created under the caller and refused edits to rows another member made; the backend reads `workspace` on writes as the owner and edit scope.

**Approved**: pending

### Mutations POST and do not re-list from the raw mutators

**Decision**: `createRow` and `updateRow` both use `POST`, and the raw mutators skip the re-list that `create`, `update`, and `remove` perform.

**Rationale**: The batch editor issues many writes and refreshes once; the backend accepts `POST` on the item path for update.

**Approved**: pending

### Derived loading flag and list identity

**Decision**: `loading` is derived from `fetching` and a ref holding the URL of the last landed list, instead of stored beside it.

**Rationale**: Two stored flags updated at several sites can drift; deriving it also keeps a same-list re-list from flashing a skeleton while a table switch does not leave the previous table's rows under a new header.

**Approved**: pending

### Stable exit-guard proxy

**Decision**: `useExitGuardChannel` keeps the live guard in a ref and returns one memoized proxy, with presence as the dirty signal.

**Rationale**: The live guard's closures change every render, so publishing it would loop; a stable proxy avoids churn in the enclosing rail host, and presence is a render value a pull-only `isDirty` cannot provide.

**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | access-patterns |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | failed | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The files are pure logic and headless hooks with no JSX or DOM access, and `server.ts` is separated from the client barrel, so separation-of-concerns passes. Unit-test-coverage passes because `conformanceVectors.test.ts` and `conformanceVectors.test.tsx` cover vectors 1 to 10, with `matchEndpoints.test.ts`, `tone.test.ts`, `exposure.test.ts`, `editability.test.ts`, `edits.test.ts`, `useCrudResource.test.tsx`, and `exitGuardChannel.test.tsx` beside them. Error handling is partial: status normalization, the `error` state, and the fail-closed gate are explicit, but the unguarded `fetch` call in `executeRequest` leaves transport failure to the caller. Server-side-authorization passes because the exposure gate is documented as presentation only and the server re-checks every request. Secure-transport is partial because `buildRequest` issues only same-origin `/api` requests and TLS comes from the hosting page. Timeout configuration and retry fail because `executeRequest` sets no timeout, no abort signal, and no retry; the single retry-on-401 lives in `@adh-sdk/auth`. Error-recovery fails for the same transport path. Data-integrity passes through the `listSeq` stale-response guard and the loud slug collision error. No-hardcoded-strings is partial because the token placeholder and the collision message are English literals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-22 | mfullerton | Covers the hub API reference shell, endpoint pages, curl snippets and the admin method helpers as phase 5 ships them; client barrel and server entry exports restated. |
| 1.1.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (conformanceVectors.test.ts, conformanceVectors.test.tsx, 10 of 10 vectors); vectors 7 and 9 text corrected to match source; unit-test-coverage now passed. |
| 1.1.2 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Inverted prohibitions (none/neither/no X MUST) restated as MUST NOT. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to data/services/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, documenting the shared headless logic of `@adh-sdk/api-explorer` and `@adh-sdk/crud`; records `executeRequest`'s network-failure propagation and absent request timeout. |
