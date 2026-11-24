
### Data shapes

- **list-envelope**: A `V1List<T>` MUST have the fields `object` (the literal `'list'`), `data` (an array of `T`), `has_more` (boolean) and `url` (string).
- **deleted-tombstone**: A `V1Deleted` MUST have the fields `id` (string), `object` (string) and `deleted` (the literal `true`). The module declares this type only; it contains no function that issues or parses a DELETE.
- **page-max**: `V1_PAGE_MAX` MUST equal 100, the widest page `/v1` serves.
- **timestamp-convention**: `created` and `updated` values on the wire MUST be treated as unix seconds, and every other timestamp as an ISO string. This is stated in the module header and enforced by no code other than the two conversion functions.

### withV1Query

- **query-append**: `withV1Query(url, params)` MUST return `url` with each entry of `params` added to its query string, and MUST return the path unchanged with no `?` when the resulting query string is empty.
- **query-drop-nullish**: `withV1Query` MUST skip a param whose value is `null` or `undefined`, leaving any same-named key already in `url` untouched.
- **query-replace**: `withV1Query` MUST replace a key already present in `url`'s query string when `params` supplies a non-nullish value for it, so a cursor can be advanced on a URL that carries one.
- **query-array-repeat**: `withV1Query` MUST emit one `key=value` pair per element when a param value is an array (for example `include[]=a&include[]=b`), after removing every earlier occurrence of that key.
- **query-empty-array**: `withV1Query` MUST remove an existing key and add nothing when a param value is an empty array, because the delete runs before the append loop.
- **query-stringify**: `withV1Query` MUST convert string, number and boolean values (and array elements) with `String(value)`.
- **query-encoding**: `withV1Query` MUST serialize the query string with `URLSearchParams`, so the key `include[]` is written percent-encoded as `include%5B%5D`, and a space is written as `+`.
- **query-preserves-fragment**: `withV1Query` MUST keep a `#fragment` at the end of the returned URL and MUST NOT parse it as part of the query.
- **query-preserves-existing-order**: `withV1Query` SHOULD leave unrelated existing query keys in their original order; a replaced key is deleted and re-appended, so it moves to the end of the query string.

### listAllV1

- **walk-all-pages**: `listAllV1<T>(url, init, opts)` MUST fetch successive pages of `url` and return their rows concatenated in the order received, stopping when a page reports `has_more` false.
- **page-size**: `listAllV1` MUST request every page with `limit=100` (`V1_PAGE_MAX`), replacing any `limit` already in `url`.
- **cursor-advance**: `listAllV1` MUST send `starting_after` set to the cursor of the previous page's last row on every page after the first, and MUST NOT add `starting_after` on the first page. A `starting_after` already present in `url` is left in place on the first page and replaced on every later page.
- **cursor-default**: When `opts.cursorOf` is not supplied, the cursor of a row MUST be its `id` converted with `String`, provided the row is a non-null object whose `id` is a string or a number; any other row has no cursor.
- **cursor-custom**: When `opts.cursorOf` is supplied, `listAllV1` MUST use it in place of the default to derive the cursor from the last row of each page.
- **keep-filters**: `listAllV1` MUST preserve every other query parameter already on `url` (for example `ecosystem_id=e1`) on every page request.
- **init-passthrough**: `listAllV1` MUST pass `init` unchanged to every page request. It does not set the HTTP method, so the request is a GET only because `init` normally carries no method.
- **stop-on-empty-page**: `listAllV1` MUST return the rows gathered so far when a page's `data` is empty, even if that page reports `has_more` true.
- **tolerate-malformed-page**: `listAllV1` MUST treat a page whose `data` is not an array as an empty page, and a missing page body (null or undefined) as an empty page with `has_more` false.
- **truncation-guard**: `listAllV1` MUST throw an `Error` whose message is `<url>: has_more is set but the last row carries no id to page from` when `has_more` is true, the page is non-empty and the last row has no cursor, rather than returning a silently truncated list. The message carries the caller's original `url`, not the paged one.
- **no-loop-guard**: `listAllV1` SHOULD NOT be relied on to detect a server that keeps returning `has_more` true with the same last row; it has no page cap, no repeated-cursor check, no timeout and no cancellation, so such a server makes the loop run until the caller's request fails.
- **error-propagation**: `listAllV1` MUST let any error thrown by `authedJson` (for example `AuthHttpError` with the HTTP status, or a network `TypeError`) propagate out unchanged and MUST discard the rows already gathered.

### listAllPublicV1 and publicJson

- **public-walk**: `listAllPublicV1<T>(url, init, opts)` MUST walk the collection exactly as `listAllV1` does (every rule above from walk-all-pages to truncation-guard holds for it), reading each page with `publicJson` in place of `authedJson`.
- **public-no-token**: `publicJson` MUST send no `Authorization` header and MUST NOT read the stored or installed access token, even when someone is signed in. A public path must not depend on who is signed in, and a token the gateway refuses on that path would otherwise refuse the read on every page.
- **public-json-body**: `publicJson<T>(url, init)` MUST call `fetch(url, init)` with the caller's headers kept, adding `content-type: application/json` only when `init` carries a body and no content type, and MUST return the parsed JSON body.
- **public-no-refresh**: `publicJson` MUST throw the `AuthHttpError` built by `responseError` on a status that is not ok, after that one request; it MUST NOT refresh a token or retry. The walk lets the error propagate unchanged.

### listV1Page

- **single-page**: `listV1Page<T>(url, init)` MUST issue exactly one `authedJson` request for `url` exactly as given, adding no `limit` or `starting_after`.
- **page-unwrap**: `listV1Page` MUST return `{ data, hasMore }`, where `data` is the page's `data` array or `[]` when it is not an array, and `hasMore` is true only when the page's `has_more` is strictly `true`.
- **page-error-propagation**: `listV1Page` MUST let any error thrown by `authedJson` propagate unchanged.

### unixToIso and isoToUnix

- **unix-to-iso**: `unixToIso(seconds)` MUST return `new Date(seconds * 1000).toISOString()` for a finite number, so `0` yields `1970-01-01T00:00:00.000Z`.
- **unix-to-iso-nullish**: `unixToIso` MUST return `null` for `null`, `undefined`, `NaN`, `Infinity` and `-Infinity`. The first overload types a plain number argument as returning a string; the second types a nullable argument as returning `string | null`.
- **unix-to-iso-range**: `unixToIso` MUST let the `RangeError` from `Date.prototype.toISOString` propagate for a finite number outside the JavaScript date range (an absolute value above 8.64e12 seconds); the function does not catch it.
- **iso-to-unix**: `isoToUnix(iso)` MUST return `Math.floor(Date.parse(iso) / 1000)`, truncating sub-second precision toward negative infinity.
- **iso-to-unix-invalid**: `isoToUnix` MUST return `NaN` for a string `Date.parse` cannot read; it does not validate its input or throw.

### Ordering and concurrency

- **sequential-pages**: `listAllV1` MUST fetch pages strictly one after another, because each request needs the previous page's last-row cursor. Concurrent `listAllV1` calls are independent; the module keeps no shared state.
- **single-threaded**: The module is single-threaded JavaScript. Its synchronous helpers (`withV1Query`, `unixToIso`, `isoToUnix`) have no ordering rule to define.

### Side effects

- **network-only**: The only side effect MUST be the HTTP requests `authedJson` and `publicJson` make. The module does not read or write storage, tokens, files or notifications, does not log, and does not mutate its inputs.

### Security

- **credential-source**: Bearer credentials are attached, and a 401 is refreshed and retried once, inside `authedJson`; this module MUST NOT read, store or log a token. `publicJson` attaches none. Token lifetime, storage and revocation are specified in the Authentication Client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)) recipe.
- **url-as-given**: The module MUST send requests to the `url` the caller passes and MUST NOT rewrite its origin; the caller owns choosing a same-origin proxy path or an authorization-server base.
- **sensitive-data-in-url**: The only caller-supplied data this module places in a URL is the paging cursor (an object id) and caller params. It MUST NOT be given secrets as params, because the URL is part of the thrown error message from `listAllV1`.

