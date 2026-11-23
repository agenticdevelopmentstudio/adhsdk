
### Pages

- **topics-list**: `PRODUCT_ADMIN_TOPICS` MUST list eight pages in this order, with these ids and paths: users (`/users`), requests, pending, invites, roles, signup-list, sets and totals, each with a label and an `href` of `/` plus its id. The ids are unique.
- **topics-importable-server-side**: the topic list MUST be importable without the client barrel, through `@adh-sdk/product-admin/topics`.

### Users pane

- **users-roster**: `ProductUsersPane` MUST list the customers of the product it is given, one page at a time, and MUST show each customer's name or email, roles, storage and whether they are paused.
- **users-search-paging**: a search MUST restart at the first page; paging forward MUST pass the last page's `nextCursor`, and paging back MUST return to the page before, kept as a stack of cursors, never recomputed. A later page that comes back empty (its last person was deleted) MUST step back a page, and MUST NOT say there are no users.
- **users-confirm-writes**: pause, unpause, quota change and delete MUST each wait for the person's confirmation in an alert dialog, and MUST send nothing when it is cancelled.
- **users-quota-gb**: the quota is entered in GB and MUST be refused, without a request, when it is above the product default (`DEFAULT_QUOTA_BYTES`, 5 GB). The pane says so.
- **users-admin-protected**: when the backend refuses a pause or delete with `admin_seat_protected`, the pane MUST say that admins cannot be paused or deleted here; any other refusal MUST be shown as the backend says it.

### Admin site page (manager)

- **admin-site-pane**: `AdminSitePane` MUST show, for the selected product, the site's current host with a form that sets it up, changes it, or removes it; MUST say so when no product is selected; and MUST show the backend's sentence when a host is refused. A removal takes the site down at once, so it MUST wait for the manager's confirmation in a destructive alert dialog, and MUST send nothing when it is cancelled.
- **admin-site-admins**: the page MUST list the holders of the `admin` role, read on the ecosystem target, and MUST add an admin as a sign-up list entry carrying the admin role's id. An address already on the list MUST keep the set its entry grants; only the role changes. After the write the Sign-up list page's cached list MUST be read again, and no other list. An address that is not an email MUST be refused without a request.
- **totals-pane**: `ProductTotalsPane` MUST show the eight totals (customers, new in 7 and 30 days, active in 7 and 30 days, storage, pending invitations, pending requests) for the product it is given, and MUST say when it is loading and when it could not load.

### Which pages move

- **admin-site-topic**: the product topic list MUST carry an `admin-site` row labeled "Admin site", for the `users` feature, that renders `AdminSitePane` with the help key `ecosystems/admin-site`.
- **visible-topics**: `visibleProductTopics(topics, site, routed)` MUST remove the `admin-site` row when the `product_admin_site` switch is off; MUST keep every row when it is on and no site exists yet; and MUST, when it is on and a site exists, remove roles, signup-list and sets and narrow the Users row (`invitations`) to its Email Signup and Authentication members (`ADMIN_SITE_KEPT_USERS_MEMBERS`, through the row's `members`), which the admin site has no page for. While the site is not known (`site` undefined: the read is in flight, or failed with no answer) it MUST keep every row but `admin-site`, and MUST keep `admin-site` too when the URL names it (`routed`), so a deep link or reload opens it.
- **run-at-admin-site**: `runAtAdminSite(topicId, site)` MUST answer true exactly when the switch is on, a site exists and the topic is invitations, roles, signup-list or sets: the question a host that answers one topic at a time (the hub's `/<slug>/<topic>` routes, where `invitations` is the roster alone) asks.
- **hide-admin-records**: the requests, pending and invites panes MUST take `hideAdminRecords`, which hides the developer's admin records: the panes MUST get neither notes slot and show no notes, no entity history and no "Admin notes" action. Without it the panes mount the notes editor and offer Admin notes.

