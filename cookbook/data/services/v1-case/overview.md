
The `/v1` API speaks snake_case and reports `created` and `updated` as unix seconds. A client whose app-facing row types are camelCase keeps those types untouched and maps at the network edge with this module. It has two pure mappers and four thin wrappers that fetch through the shared authenticated request layer and map the result.

- `fromV1` turns a `/v1` object, or an array of them, into the camelCase row the client was written against.
- `toV1Body` turns a camelCase request body into the snake_case body `/v1` accepts.
- `v1Write`, `v1Json`, `v1List` and `v1Page` compose those mappers with `authedJson`, `listAllV1` and `listV1Page`, which this module imports from the data package's `http` module (a re-export of the auth package's client).

The source's header comment explains why the mapping is not a plain case conversion. The gateway renames only the properties the legacy spec declares. A property it does not know, such as a work item's `itemKey` or an iteration row's `projectName`, passes through in camelCase. So `fromV1` camelizes idempotently: `project_id` and `projectId` both land on `projectId`. Free-form maps keep the keys they were stored with and are never re-cased.

This is shared code with no visual surface. Authentication, token refresh, pagination cursoring, and HTTP error construction belong to the auth package's client and are described by [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104).

