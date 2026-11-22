
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

