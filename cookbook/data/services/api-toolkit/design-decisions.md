
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

