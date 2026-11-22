
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

