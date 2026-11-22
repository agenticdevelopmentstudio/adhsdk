
- **Data collected**: Ecosystem administrative metadata only - `name`,
  `slug`/`identifier`, `description`, `region`, primary domain, timestamps,
  and the caller's own `canManage` flag. None of these fields are personal
  data about an end user; they describe a product/ecosystem record, not a
  person. Two fields do refer to people: the auth settings' `loginAllowedEmails`, the
  email addresses an owner lists as allowed to sign in, which are contact details; and the
  provisioner principal id on a provisioned feature row, an opaque id. This data layer passes the
  emails through as given (the ecosystem-config form trims and lowercases them before
  saving), and nothing here stores them beyond the in-memory query cache.
- **Storage**: One reference implementation holds no cache of its own -
  every call is a live round-trip to whatever data source the host
  supplies. The other holds results in a shared in-memory query-client
  cache, keyed as documented under each hook/query above; nothing in this
  component writes to durable browser/device storage.
- **Transmission**: All calls travel through the injected data source or
  the shared Bearer-token client (see [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); this component itself
  attaches no credentials and reads no cookies.
- **Retention**: One reference implementation retains nothing between
  calls. The other's cache entries persist per their cache key until
  invalidated by the matching mutation (as documented per hook above) or
  garbage-collected by the query library's own cache lifetime; the only
  custom cache settings are the workspace-default and hub-child queries'
  no-retry configuration and the 30-minute freshness window of the feature
  catalog and each ecosystem's availability list, and
  no explicit garbage-collection time is set anywhere. Provisioned feature
  rows carry who provisioned them (a principal id or nothing), held only in
  that in-memory cache.

