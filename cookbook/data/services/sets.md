---
id: a273158e-3129-4e69-ab08-a651235303e0
title: "Sets Client"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-22
modified: 2026-11-22
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "Web client for an ecosystem's sets admin API: sets, containment, values, grants, effective answers, offer sets, typed 422 refusals and catalog set entries."
platforms:
  - typescript
  - web
tags:
  - data
  - sets
  - permissions
  - api
  - errors
depends-on:
  - 870c182f-1a80-4254-8fec-3eb35c8f13f7
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
related: []
references:
  - packages/web/packages/data/src/sets/sets.ts (adhsdk)
  - packages/web/packages/data/src/sets/wire.ts (adhsdk)
  - packages/web/packages/data/src/sets/index.ts (adhsdk)
  - packages/web/packages/data/src/sets/__tests__/sets.test.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Sets Client

## Overview

This is the client for the backend's sets admin surface (phase 5), written for an ecosystem's managers. A set is a named bundle of an ecosystem's permissions (catalog features) and limits (typed values such as a usage tier). Sets contain other sets. A customer holds sets through grants (an offer bought, a direct grant, the sign-up list), and the backend resolves what the customer holds into one effective answer. The backend owns every rule; this code only builds requests, maps `snake_case` wire rows to `camelCase` rows, and turns the backend's 422 `set_refused` body into a typed error.

The component is three files in `packages/web/packages/data/src/sets/`. `wire.ts` declares the types: the `camelCase` shapes the panes consume (`SetRow`, `SetGrantRow`, `EffectiveSets`, `UnresolvedSets`, `SetsAnswer`, `SetInput`, `SetPatch`, `SetValue`, `SetRefusal`, `SetEntries`, `SetLimitEntry`, `SetLimitType`, `SetGrantSource`) and the `*Wire` shapes they map from (`SetWire`, `SetGrantWire`, `SetsAnswerWire`, `SetEntriesWire`). `sets.ts` holds the mappers, the refusal error, the `setsApi` object and the catalog helpers. `index.ts` is the package entry `@adh-sdk/data/sets` and re-exports both with `export *`.

Every request goes through `authedJson` or `authedRequest` and the list walker `listAllV1`, with query strings built by `withV1Query`; those come from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)). Bearer-token attachment and the single refresh-and-retry on a 401 are inherited from there, not repeated here.

The routes, as the file header lists them:

| Route | Verb | Client function |
|---|---|---|
| `/api/v1/sets` | GET | `setsApi.list` |
| `/api/v1/sets` | POST | `setsApi.create` |
| `/api/v1/sets/{id}` | POST | `setsApi.edit` |
| `/api/v1/sets/{id}` | DELETE | `setsApi.remove` |
| `/api/v1/sets/{id}/members` | POST | `setsApi.setMembers` |
| `/api/v1/sets/{id}/values` | POST | `setsApi.setValues` |
| `/api/v1/set_grants?customer=` | GET | `setsApi.grants` |
| `/api/v1/set_grants` | POST | `setsApi.grant` |
| `/api/v1/set_grants/{id}` | DELETE | `setsApi.revoke` |
| `/api/v1/set_grants/effective/{customer_id}` | GET | `setsApi.effective` |
| `/api/v1/offers/{offer_id}/set` | POST | `setsApi.setOfferSet` |

## Behavioral Requirements

### Wire rows and mapping

- **set-row-mapping**: `toSet` MUST map a `SetWire` to a `SetRow` with `id`, `slug`, `name`, `contains` and `values` copied as is, `isDefault` from `is_default`, `isPersonal` from `is_personal`, and `personalCustomerId` from `personal_customer_id`.
- **set-row-defaults**: `toSet` MUST read an absent or null `description` as `""`, an absent `personal_customer_id` as `null`, an absent `contains` as `[]` and an absent `values` as `[]`.
- **grant-row-mapping**: `toSetGrant` MUST map a `SetGrantWire` to a `SetGrantRow` with `ecosystemId` from `ecosystem_id`, `customerId` from `owner_id`, `setId` from `set_id`, `grantedBy` from `granted_by`, `grantedAt` from `granted_at`, and `id` and `source` unchanged.
- **grant-row-defaults**: `toSetGrant` MUST read an absent `billing_account_id`, `revoked_at` or `revoke_reason` as `null`.
- **grant-timestamps-verbatim**: `toSetGrant` MUST pass `granted_at` and `revoked_at` through as the strings received, with no conversion.
- **value-passthrough**: `toSet` MUST NOT validate or convert a `SetValue`; `kind`, `key` and `value` (typed `unknown`) reach the caller as received, and limit keys such as `usage.tier` are never re-cased.

### The sets answer

- **answer-absent**: `toSetsAnswer` MUST return `null` when given `null` or `undefined` (an older backend, or a realm where sets do not apply).
- **answer-unresolved**: `toSetsAnswer` MUST return exactly `{ error: "unresolved" }` when the wire value's `error` is `"unresolved"`, discarding every other field.
- **answer-effective**: `toSetsAnswer` MUST otherwise return an `EffectiveSets` with `held`, `permissions` and `readOnly` (from `read_only`) defaulting to `[]` and `limits` defaulting to `{}`.
- **answer-valid-until**: `toSetsAnswer` MUST include `validUntil` only when the wire `valid_until` is not `undefined`, and MUST keep a `null` value as `null`; when the key is absent the result has no `validUntil` key.
- **answer-guard**: `isEffectiveSets` MUST return `false` for `null` and for any value that has an `error` key, and `true` otherwise.

### Catalog set entries

- **entries-absent**: `toSetEntries` MUST return `undefined` when given `undefined`, or when the wire value has no `permission` and no non-empty `limits`.
- **entries-shape**: `toSetEntries` MUST otherwise return a `SetEntries` that has `permission: true` only when the wire `permission` is truthy and a `limits` array only when the wire `limits` is non-empty.
- **entries-limits-copied**: `toSetEntries` MUST copy each limit entry (`key`, `type`, `label`) into a new object rather than reuse the wire object.
- **entry-features**: `setEntryFeatures` MUST return one `{ key, label, setEntries }` per catalog feature whose `setEntries` is set, in catalog order, and MUST drop every other feature.

### Refusals

- **refusal-detect**: `asSetRefusedError` MUST return a `SetRefusedError` when the thrown value's HTTP status is 422, `body.error.code` is `"set_refused"` and `body.error.rule` is a number, and MUST return `null` in every other case.
- **refusal-duck-typed**: `asSetRefusedError` MUST read the status through `httpStatus` and the body through a `.body` property, never through `instanceof` on one error class, so a host's own auth error class is read the same; a non-`Error` value with a `status` property yields `null`.
- **refusal-fields**: The `SetRefusal` built by `asSetRefusedError` MUST carry `rule` (the number as received, cast to the rule union without range checking), `message` (the body's `error.message` when it is a string, else the thrown error's own message), and MUST add `limits` only when `error.limits` is an array, `containers` only when `error.containers` is an array and `customers` only when `error.customers` is a number.
- **refusal-error-class**: `SetRefusedError` MUST extend `Error`, MUST set its `name` to `"SetRefusedError"`, MUST use `refusal.message` as its `message`, and MUST expose the `SetRefusal` as the read-only property `refusal`.
- **refusal-rule-meaning**: The `SetRefusal.rule` field MUST be read by the rule it would break: 3 (a container whose contained sets disagree on a limit must define it), 4 (the customer holds a conflicting set), 6 (a containment loop), 8 (the edit unsettles a container or puts a holder in conflict) and 9 (the set conflicts with another live offer's set). The type also admits 1 and 2, which the doc comment does not describe.

### The setsApi calls

- **ecosystem-query**: Every `setsApi` call MUST name the ecosystem as `ecosystem=<ecoId>` in the query string, built by `withV1Query`, so the id is form-encoded (a space is written `+`).
- **id-encoding**: Every set id, grant id, customer id and offer id placed in a path MUST be encoded with `encodeURIComponent`.
- **list-sorted**: `setsApi.list` MUST fetch every page of `/api/v1/sets` with `listAllV1`, map each row with `toSet`, and return the rows sorted by `name` with `localeCompare`.
- **list-personal**: `setsApi.list` MUST add `personal=true` only when `opts.personal` is truthy, and MUST send no `personal` param otherwise (including for `false`).
- **create-body**: `setsApi.create` MUST POST to `/api/v1/sets` a body that always carries `slug` and `name`, adds `description` and `is_default` only when the input value is not `undefined`, and adds `personal_customer_id` only when `personalCustomerId` is truthy.
- **create-returns**: `setsApi.create` MUST return the created set mapped with `toSet`.
- **edit-body**: `setsApi.edit` MUST POST (not PUT or PATCH) to `/api/v1/sets/{id}` a body carrying only the patch fields (`slug`, `name`, `description`, `isDefault` as `is_default`) that are not `undefined`, and MUST return the edited set mapped with `toSet`.
- **edit-default-clears**: Making a set the default (`isDefault: true`) MUST be a plain edit; clearing the flag on the previous default is the backend's doing, and the client sends nothing extra.
- **remove-delete**: `setsApi.remove` MUST send a DELETE with no body to `/api/v1/sets/{id}` through `authedRequest` and MUST resolve with no value.
- **members-replace**: `setsApi.setMembers` MUST POST `{ contains }` to `/api/v1/sets/{id}/members`, replacing the whole containment list, and MUST return the set mapped with `toSet`.
- **values-replace**: `setsApi.setValues` MUST POST `{ values }` to `/api/v1/sets/{id}/values`, replacing the whole value list, and MUST return the set mapped with `toSet`. That every key is one the catalog's `setEntries` declares, with a value of its type, is a caller precondition the backend enforces; the client does not check it.
- **grants-list**: `setsApi.grants` MUST fetch every page of `/api/v1/set_grants` with `customer=<customerId>` added to the ecosystem query and MUST map each row with `toSetGrant`; revoked grants are included, and the order is the backend's (the doc comment says newest first), as the client does not sort.
- **grant-call**: `setsApi.grant` MUST POST `{ customer_id, set_id }` to `/api/v1/set_grants` and MUST return `{ grantId, revoked }` from the response's `grant_id` and `revoked`, reading an absent `revoked` as `[]`. Granting a set already held returns that grant (backend behavior, per the doc comment).
- **revoke-call**: `setsApi.revoke` MUST send a DELETE with no body to `/api/v1/set_grants/{id}` through `authedRequest` and MUST resolve with no value; the row stays on the backend with the reason `direct`.
- **effective-call**: `setsApi.effective` MUST GET `/api/v1/set_grants/effective/{customerId}` and MUST return the body mapped with `toSetsAnswer`, so the result is `null`, `{ error: "unresolved" }` or an `EffectiveSets`. The answer is the customer's before the ecosystem's ceiling.
- **offer-set-call**: `setsApi.setOfferSet` MUST POST `{ set_id: setId }` to `/api/v1/offers/{offerId}/set`, sending `null` unchanged to stop the offer granting a set, and MUST resolve with no value, discarding the response body.
- **write-refusal-conversion**: `create`, `edit`, `remove`, `setMembers`, `setValues`, `grant` and `setOfferSet` MUST rethrow a backend 422 `set_refused` as a `SetRefusedError` (through the module's `write` wrapper, which `post` also uses).
- **revoke-refusal-conversion**: `setsApi.revoke` calls `authedRequest` directly rather than the `write` wrapper, and MUST NOT convert any error: the backend's revoke route (`DELETE /api/v1/set_grants/{id}`) answers 204, or an error from the ecosystem check (404 for an unknown ecosystem, 403 when the caller does not manage it) or 404 for an unknown or malformed grant id, and never a 422 `set_refused`, so there is nothing to convert. The file header's "every write here" covers the writes that can be refused.
- **other-errors-unchanged**: A thrown value that is not a 422 `set_refused` MUST propagate from every `setsApi` call as the same object, unwrapped.
- **no-transport-policy**: The client MUST NOT add a timeout, retry, cancellation, caching or logging of its own; each call sends one request (or one `listAllV1` walk) with no idempotency key, and the transport owns the 401 refresh.
- **client-directive**: `sets.ts` MUST carry the `"use client"` directive.
- **entry-point**: `index.ts` MUST re-export everything from `./sets` and `./wire`.

## Appearance

Not applicable: this is a data client with mappers and types, not a visual component.

## States

Not applicable: this is a data client with no visual states; every `setsApi` call is a stateless request and the module keeps no state between calls.

## Accessibility

Not applicable: this is a data client with no user interface; the Sets pane that consumes it is a separate component.

## Conformance Test Vectors

Vectors marked with a test name are asserted in `packages/web/packages/data/src/sets/__tests__/sets.test.ts`, which stubs only `authedJson`, `authedRequest` and `listAllV1`. The others follow from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sets-001 | set-row-mapping, list-sorted, ecosystem-query, list-personal | `list("eco 1")` with rows named Team then Pro (test: "lists the ecosystem's sets by name, camel-cased; personal sets only when asked") | `listAllV1` called with `/api/v1/sets?ecosystem=eco+1`; result names `["Pro","Team"]`; first row `{id:"s-1",slug:"pro",name:"Pro",description:"",isDefault:false,isPersonal:false,personalCustomerId:null,contains:["s-0"],values:[{kind:"limit",key:"usage.tier",value:"pro"}]}` |
| sets-002 | list-personal | `list("eco-1", {personal:true})` (same test) | `listAllV1` called with `/api/v1/sets?ecosystem=eco-1&personal=true` |
| sets-003 | set-row-defaults | `toSet` of a wire row with `description: null`, no `personal_customer_id`, no `contains`, no `values` | `description:""`, `personalCustomerId:null`, `contains:[]`, `values:[]` |
| sets-004 | create-body, create-returns | `create("eco-1", {slug:"pro",name:"Pro",isDefault:true})` (test: "creates and edits with snake_case bodies, sending only what is given") | POST `/api/v1/sets?ecosystem=eco-1`, body `{slug:"pro",name:"Pro",is_default:true}` |
| sets-005 | create-body | `create("eco-1", {slug:"me",name:"Me",personalCustomerId:"c-1"})` (same test) | body `{slug:"me",name:"Me",personal_customer_id:"c-1"}` |
| sets-006 | create-body | `create("eco-1", {slug:"a",name:"A",personalCustomerId:null,description:""})` | body `{slug:"a",name:"A",description:""}` (null customer omitted, empty description sent) |
| sets-007 | edit-body, id-encoding | `edit("eco-1","s-1",{name:"Pro plus"})` (same test) | POST `/api/v1/sets/s-1?ecosystem=eco-1`, body `{name:"Pro plus"}` |
| sets-008 | edit-default-clears | `edit("eco-1","s-1",{isDefault:true})` | body `{is_default:true}` and nothing else |
| sets-009 | remove-delete | `remove("eco-1","s-1")` (test: "deletes by id") | `authedRequest("/api/v1/sets/s-1?ecosystem=eco-1", {method:"DELETE"})`; resolves with no value |
| sets-010 | members-replace | `setMembers("eco-1","s-1",["s-0","s-3"])` (test: "replaces containment and values on their own routes") | POST `/api/v1/sets/s-1/members?ecosystem=eco-1`, body `{contains:["s-0","s-3"]}` |
| sets-011 | values-replace | `setValues("eco-1","s-1",[{kind:"permission",key:"storage",value:true},{kind:"limit",key:"storage.bytes",value:1024}])` (same test) | POST `/api/v1/sets/s-1/values?ecosystem=eco-1`, body `{values:[...]}` unchanged |
| sets-012 | id-encoding | `edit("eco-1","a/b",{name:"x"})` | URL path is `/api/v1/sets/a%2Fb` |
| sets-013 | grants-list, grant-row-mapping, grant-row-defaults | `grants("eco-1","c-1")` with an `owner_id:"c-1"` row (test: "lists a customer's grants, owner_id read as the customer") | `listAllV1` called with `/api/v1/set_grants?ecosystem=eco-1&customer=c-1`; row has `customerId:"c-1"`, `setId:"s-1"`, `source:"direct"`, `revokedAt:null` |
| sets-014 | grant-timestamps-verbatim | `toSetGrant` with `revoked_at:"2026-11-02T00:00:00.000Z"` | `revokedAt:"2026-11-02T00:00:00.000Z"` |
| sets-015 | grant-call | `grant("eco-1",{customerId:"c-1",setId:"s-2"})` with response `{grant_id:"g-2",revoked:["g-1"]}` (test: "grants, reporting what the grant revoked, and revokes by grant id") | POST `/api/v1/set_grants?ecosystem=eco-1`, body `{customer_id:"c-1",set_id:"s-2"}`; returns `{grantId:"g-2",revoked:["g-1"]}` |
| sets-016 | grant-call | `grant` with response `{grant_id:"g-3"}` | returns `{grantId:"g-3",revoked:[]}` |
| sets-017 | revoke-call | `revoke("eco-1","g-2")` (same test as sets-015) | `authedRequest` URL `/api/v1/set_grants/g-2?ecosystem=eco-1` |
| sets-018 | effective-call, answer-effective, answer-valid-until, answer-guard | `effective("eco-1","c-1")` with `{held:["s-1"],permissions:["storage"],read_only:[],limits:{"usage.tier":"pro"},valid_until:null}` (test: "reads the effective answer in each of its three forms") | URL `/api/v1/set_grants/effective/c-1?ecosystem=eco-1`; result `{held:["s-1"],permissions:["storage"],readOnly:[],limits:{"usage.tier":"pro"},validUntil:null}`; `isEffectiveSets` true |
| sets-019 | answer-absent, answer-unresolved, answer-guard | `toSetsAnswer(null)`, `toSetsAnswer(undefined)`, `toSetsAnswer({error:"unresolved"})` (same test) | `null`, `null`, `{error:"unresolved"}`; `isEffectiveSets` is false for the unresolved value and for `null` |
| sets-020 | answer-effective, answer-valid-until | `toSetsAnswer({})` | `{held:[],permissions:[],readOnly:[],limits:{}}` with no `validUntil` key |
| sets-021 | answer-unresolved | `toSetsAnswer({error:"unresolved", held:["s-1"]})` | `{error:"unresolved"}` only |
| sets-022 | offer-set-call | `setOfferSet("eco-1","o-1","s-1")` then `setOfferSet("eco-1","o-1",null)` (test: "sets or clears the set an offer sells") | POST `/api/v1/offers/o-1/set?ecosystem=eco-1`; bodies `{set_id:"s-1"}` then `{set_id:null}`; both resolve with no value |
| sets-023 | refusal-detect, refusal-fields, refusal-error-class, write-refusal-conversion | `setMembers("eco-1","s-1",["s-1"])` rejected with a 422 `AuthHttpError` whose body error is `{code:"set_refused",message:"a containment loop",rule:6}` (test: "turns a 422 set_refused into a SetRefusedError carrying the rule") | rejects with a `SetRefusedError` whose `refusal` equals `{rule:6,message:"a containment loop"}` |
| sets-024 | refusal-fields | `asSetRefusedError` of a 422 with `rule:8, limits:["usage.tier"], containers:["s-9"], customers:2` (test: "keeps the limits, containers and holder count a refusal names") | `refusal` equals `{rule:8,message:"m",limits:["usage.tier"],containers:["s-9"],customers:2}` |
| sets-025 | refusal-fields | 422 `set_refused` with a numeric `rule` and no `message` in the body | `refusal.message` equals the thrown error's own message |
| sets-026 | refusal-detect, refusal-duck-typed | `asSetRefusedError` of a 422 with `code:"invalid"`, of a 400 error, and of `new Error("network")` (test: "leaves every other error as it was") | `null` for each |
| sets-027 | refusal-detect | 422 whose body `error.code` is `"set_refused"` but whose `rule` is the string `"6"` | `null` |
| sets-028 | refusal-duck-typed | A plain object (not an `Error`) with `status:422` and a `set_refused` body | `null` |
| sets-029 | other-errors-unchanged | `create("eco-1",{slug:"a",name:"A"})` where `authedJson` rejects with a 403 `AuthHttpError` (same test as sets-026) | rejects with that same error object |
| sets-030 | entries-absent, entries-shape, entries-limits-copied | `toSetEntries({limits:[]})`; `toSetEntries(undefined)`; `toSetEntries({permission:true,limits:[{key:"storage.bytes",type:"bytes",label:"Storage"}]})` (the test "maps set_entries onto the catalog feature, and drops an empty one" asserts only the `{limits:[]}` case; the others follow from the source) | `undefined`; `undefined`; `{permission:true,limits:[{key:"storage.bytes",type:"bytes",label:"Storage"}]}` with the limit a new object |
| sets-031 | entries-shape | `toSetEntries({permission:true})` | `{permission:true}` with no `limits` key |
| sets-032 | entry-features | `setEntryFeatures` of features b (permission entry), a (none), c (a tier limit) (test: "keeps only the features that contribute, in catalog order") | keys `["b","c"]` |
| sets-033 | revoke-refusal-conversion | `revoke("eco-1","g-2")` where `authedRequest` rejects with a 422 `set_refused` | rejects with the raw 422 error, not a `SetRefusedError` (follows from the source; the backend's revoke route never sends this body) |
| sets-034 | entry-point, client-directive | Import `asSetRefusedError`, `setsApi`, `toSetsAnswer` and the type `SetRow` from the package entry `@adh-sdk/data/sets` | All resolve; the tests import the values (not the type) from `..` (the `index.ts`) |
| sets-035 | no-transport-policy | `list("eco-1")` where `listAllV1` rejects with a network error | `list` rejects with that error; no retry is made and `listAllV1` is called once |
| sets-036 | refusal-rule-meaning | `asSetRefusedError` of a 422 `set_refused` with `rule:9` | `refusal.rule` equals 9; a rule number outside the union (for example 5) is accepted and passed through unchecked |

## Edge Cases

- **Empty and absent wire data (MUST)**: A list with no rows returns `[]`; a `SetWire` missing `description`, `contains`, `values` or `personal_customer_id` maps to the defaults in `set-row-defaults`; an effective body `{}` maps to empty arrays and `{}` limits; `null` or `undefined` maps to `null`.
- **Empty ecosystem id (MUST NOT validate)**: `ecoId` is not validated. An empty string is not nullish, so it is sent as `ecosystem=`; the backend decides the response.
- **Falsy inputs on create (MUST)**: An empty-string or `null` `personalCustomerId` is omitted from the create body; an empty-string `description` or an `isDefault` of `false` is sent, because only `undefined` is dropped.
- **Falsy inputs on edit (MUST)**: A patch of `{ isDefault: false }` sends `is_default: false`; only `undefined` fields are dropped.
- **Empty replacement lists (MUST)**: `setMembers` with `[]` and `setValues` with `[]` send the empty array as the replacement; the client does not treat it as a no-op.
- **Boundary rule values (MUST)**: A `rule` that is any number is accepted, with no check against 1, 2, 3, 4, 6, 8 or 9.
- **Malformed refusal body (MUST)**: A 422 with no body, a null body, a body without `error`, a different `code`, or a non-numeric `rule` is not a refusal; the original error is rethrown. A non-string `message` falls back to the thrown error's message; a non-array `limits` or `containers` and a non-number `customers` are dropped.
- **Backend errors (MUST)**: A 401 follows the transport's single refresh and retry. Any other status error (400, 403, 404, 409, 5xx) propagates unchanged. The effective route answers 200 with `{ error: "unresolved" }` whenever the backend's resolver could not compute the answer, so that body maps to the `unresolved` case; its 403 is the ecosystem-management check and propagates. The `UnresolvedSets` doc comment places a 403 for the enforcement-on case on the enforcing requests (such as `/auth/me`), not on this route.
- **204 on a JSON call (MUST)**: `authedJson` throws on a 204 with no body, so every call that goes through it (the POSTs, `effective`) needs a response body; `remove` and `revoke` use `authedRequest`, which ignores the body and so accept a 204.
- **Offline or unreachable server (MUST)**: A network failure rejects the call with the transport's error, unconverted; there is no retry, queue or cache.
- **Concurrent calls (MUST)**: Concurrent calls do not interact. The module has no shared mutable state, and the client does not order or serialize them; two writes on the same set are ordered by the backend, and the client carries no version or precondition to detect a lost update.
- **Partial failure on a multi-page read (MUST)**: A failure on any page rejects the whole `list` or `grants` call; no partial rows are returned.
- **Revoked grant on a customer (MUST)**: `grants` returns revoked rows with `revokedAt` and `revokeReason` set; the client does not filter them.
- **Customer or set id with reserved characters (MUST)**: Path ids are percent-encoded; query values are form-encoded.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecoId` | string | none, required | The ecosystem id every call names as `?ecosystem=<id>`. |
| `opts.personal` | boolean | `undefined` (omitted) | On `setsApi.list`, adds `personal=true` to include personal sets. |
| `SETS` | string constant | `/api/v1/sets` | Module-private base route for sets. |
| `GRANTS` | string constant | `/api/v1/set_grants` | Module-private base route for grants. |
| Transport | injected module imports | `authedJson`, `authedRequest`, `httpStatus`, `listAllV1`, `withV1Query` from `../http`, `enc` and `sortByText` from `../client-helpers` | The caller's environment supplies the token and base URL through the shared HTTP layer; this module reads no environment variable or setting. |

## Deep Linking

Not applicable: this is a data client; it declares no URL scheme or route of its own, only the backend `/api/v1` paths it calls.

## Localization

Not applicable: the module defines no user-facing string. A refusal's `message` is the backend's text (or the thrown error's own message), passed through untranslated.

## Accessibility Options

Not applicable: this is a data client with no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the module reads no flag. Whether sets apply to an ecosystem is the backend's decision, reported as a `null` answer (sets absent) or `{ error: "unresolved" }` (the backend's resolver could not compute the answer).

## Analytics

Not applicable: the module emits no event.

## Privacy

- **Data collected**: None by this module. It carries customer ids, set ids, grant rows (including `billing_account_id` and `granted_by`) and effective answers in transit between the backend and the caller.
- **Storage**: None; rows live in local variables and are returned to the caller.
- **Transmission**: Each call goes to the `/api/v1` path on the backend with the bearer token attached by the transport; the ecosystem id and customer id appear in the query string or path. Authorization to read or change sets is the backend's decision; the client sends the token and relays a 403.
- **Retention**: None; nothing is cached between calls.

## Logging

Not applicable: neither `sets.ts` nor `wire.ts` contains a log call; a failure surfaces only as a thrown error.

## Platform Notes

- **SwiftUI**: Port the wire types as `Codable` structs with `CodingKeys` (or a `snake_case` key decoding strategy, which also re-cases the keys of the `limits` dictionary, so decode that with a strategy-free path to keep keys as received) and `SetValue.value` as a small `JSONValue` enum, since the source types it `unknown`. `SetsAnswer` becomes an enum with cases `none`, `unresolved` and `effective(EffectiveSets)`. `SetRefusedError` becomes a `struct SetRefusedError: Error` holding a `SetRefusal`. `setsApi` becomes a struct of `async throws` methods over `URLSession`, with `URLComponents` in place of `withV1Query` and `addingPercentEncoding` for path ids; `URLComponents` writes a space as `%20`, not `+`, so encode the ecosystem query by hand if the gateway compares bytes. Use `localizedStandardCompare` or `localizedCompare` where the source uses `localeCompare` for the name sort.
- **Compose**: Use `kotlinx.serialization` data classes with `@SerialName`, `JsonElement` for `SetValue.value` and limit values, and a sealed interface for `SetsAnswer` (`None`, `Unresolved`, `Effective`). `SetRefusedError` is an `Exception` subclass carrying the `SetRefusal`. Implement `setsApi` as `suspend` functions over Retrofit or Ktor, build queries with `HttpUrl.Builder`, and sort with `sortedWith(compareBy(Collator.getInstance()) { it.name })` to match `localeCompare`. Catch the HTTP exception, check for 422, parse the error body and rethrow as `SetRefusedError`.
- **React/Web**: This is the source platform: `packages/web/packages/data/src/sets/sets.ts` (client), `wire.ts` (types) and `index.ts` (the `@adh-sdk/data/sets` entry), with tests in `packages/web/packages/data/src/sets/__tests__/sets.test.ts`. The file carries the `"use client"` directive, imports `authedJson`, `authedRequest`, `httpStatus`, `listAllV1` and `withV1Query` from `../http` and `enc` and `sortByText` from `../client-helpers`. The refusal check is duck-typed on `.status` and `.body` so two coexisting `AuthHttpError` classes are read alike, and `SetRefusedError` sets `name` by hand so the error reports that name rather than `Error`.
- **AppKit / UIKit**: Same Foundation approach as SwiftUI: `async throws` methods over `URLSession.data(for:)`, `JSONDecoder` with `keyDecodingStrategy` set to `convertFromSnakeCase` (it also re-cases dictionary keys such as those in `limits`, which the source never does), and a typed `SetRefusedError` thrown from a shared write helper. Wrap in a `Task` for completion-handler call sites; nothing in the contract needs the main thread, though results that feed a table view should be applied on it.
- **WinUI 3**: Use one shared `System.Net.Http.HttpClient` with a `DelegatingHandler` that attaches the bearer header and does the single refresh-and-retry on 401, and `System.Text.Json` with `[JsonPropertyName("is_default")]` style attributes on records for `SetWire` and the other wire shapes (or a `JsonNamingPolicy.SnakeCaseLower` option on .NET 8 and later). Model `SetValue.Value` as `JsonElement` and `SetsAnswer` as a record hierarchy (`NoSets`, `UnresolvedSets`, `EffectiveSets`) with a `JsonConverter` that picks the case from a missing body, an `error` property or the effective fields. Implement `SetRefusedException : Exception` carrying a `SetRefusal` record, thrown by a `WriteAsync<T>` helper that catches `HttpRequestException` (with `StatusCode == HttpStatusCode.UnprocessableEntity`) or a custom handler exception, parses the body with `JsonDocument`, and checks `error.code == "set_refused"` and a numeric `error.rule` as the source does. Expose `SetsApi` methods as `Task<T>` returning `async` methods taking a `CancellationToken` (the source has none), build queries with `QueryHelpers.AddQueryString` or `HttpUtility.ParseQueryString` (`HttpUtility` writes a space as `+` like `URLSearchParams`; `QueryHelpers` writes `%20`), encode path ids with `Uri.EscapeDataString`, and sort with `string.Compare(a, b, StringComparison.CurrentCulture)`. Return lists as `IReadOnlyList<T>`; if a pane binds them, copy into an `ObservableCollection<T>` on the UI thread after the call completes, since the source returns whole lists and keeps no observable state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/sets/sets.ts` | confirmed (1.0.0) |
| web | `packages/web/packages/data/src/sets/wire.ts` | confirmed (1.0.0) |
| web | `packages/web/packages/data/src/sets/index.ts` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Writes convert a 422 `set_refused` into a typed `SetRefusedError` carrying the rule, limits, containers and holder count, and leave every other error untouched.
**Rationale**: The file header says it exists "so a pane can say which rule and which limits". Rethrowing every other error unchanged keeps the transport's 401, 403 and 5xx handling in one place.
**Approved**: pending

**Decision**: `asSetRefusedError` identifies the error by duck-typing on `.status` and `.body` through `httpStatus`, not by `instanceof`.
**Rationale**: The doc comment says a host's own auth error class is read the same; two `AuthHttpError` classes can coexist when a host layers its own client over this package.
**Approved**: pending

**Decision**: Request bodies send only the fields given (`undefined` is dropped, `null` and empty values are kept), except that `personalCustomerId` is sent only when truthy.
**Rationale**: Edit is a true partial: "what is left out stays as it is" (`SetPatch` doc comment). A personal set's customer is "fixed once made" (`SetInput`), so an empty or null value is never worth sending.
**Approved**: pending

**Decision**: Containment and values are replaced wholesale on their own routes, not patched through `edit`.
**Rationale**: The doc comments say "Replace the sets it contains" and "Replace its permissions and limits", and the backend checks rules 3, 6 and 8 against the whole list at once. `SetPatch` is limited to `slug`, `name`, `description` and `isDefault`.
**Approved**: pending

**Decision**: Edit is a POST rather than a PUT or PATCH.
**Rationale**: The route table in the file header lists "edit (POST)", and the test asserts the method; the backend defines the verb, and a port must match it.
**Approved**: pending

**Decision**: The client does not validate set values, containment, rule numbers or ids before sending.
**Rationale**: The backend's resolver owns the rules (3, 4, 6, 8, 9) and refuses a bad write with a named rule; duplicating them on the client would drift. The cost is a round trip for an invalid write.
**Approved**: pending

**Decision**: `toSetsAnswer` reads `null` or `undefined` as `null` and `{ error: "unresolved" }` as its own case, and `isEffectiveSets` is the type guard that separates the three.
**Rationale**: The doc comment says absence means "an older backend, or a realm where sets do not apply", and `UnresolvedSets` means the backend could not compute the answer; callers must tell "no sets" from "could not compute".
**Approved**: pending

**Decision**: `validUntil` is omitted from the mapped answer when the wire key is absent, and kept as `null` when the wire value is `null`.
**Rationale**: `EffectiveSets.validUntil` is "absent on `/auth/me`"; the conditional spread preserves that absence, so a consumer can tell "not reported" from "never changes".
**Approved**: pending

**Decision**: `revoke` does not use the `write` wrapper that converts refusals.
**Rationale**: The call goes straight to `authedRequest`. The backend's revoke route never answers a 422 `set_refused`, so there is nothing to convert, and the header's "every write here" covers the writes that can be refused.
**Approved**: pending

**Decision**: `grants` returns the backend's order and `list` sorts by name on the client with `localeCompare`.
**Rationale**: The doc comment says grants arrive "newest first" from the backend, while sets have no stated order and the pane wants them by name. `localeCompare` is locale-dependent, so two machines may order accented names differently.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |

The module keeps wire types, mapping, refusal typing and the route table apart from transport, which it delegates wholly to the shared HTTP layer, so separation of concerns passes. Unit-test coverage is partial: `sets.test.ts` asserts the routes, bodies, mapping, the three answer forms, refusal conversion and the catalog helpers, but it does not exercise the `toSet` defaults for an absent `description`, `contains` or `values`, the fallback to the thrown error's message, the empty-`revoked` default on `grant`, the falsy-input rules on create and edit, or the refusal path of `revoke`. API-design conventions and pagination pass because both list calls walk every page through `listAllV1` and build queries with `withV1Query`. Error-response handling is partial: the 422 `set_refused` body is parsed into a typed error on seven calls, other errors propagate unchanged, and `revoke` does not convert a refusal. Timeout configuration fails because the module sets no deadline and exposes no abort path of its own, and no `setsApi` method accepts an `AbortSignal`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
