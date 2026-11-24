
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

