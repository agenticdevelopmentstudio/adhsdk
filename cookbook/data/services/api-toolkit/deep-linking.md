
`slug.ts` exists to give each endpoint a crawlable route: `endpointSlug` projects an endpoint to path segments with braces stripped plus the lower-cased method, `GET /persona/personas/{id}` becoming `persona/personas/id/get`, and `endpointForSlug` reverses it, returning `undefined` on a miss. `allEndpoints` enumerates the routes to prerender. No other given source defines a URL scheme.

