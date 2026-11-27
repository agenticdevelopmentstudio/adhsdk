
**Decision**: The row carries `consoleLive` as its own field rather than the caller combining `adminEnabled` with `adminClientId`.
**Rationale**: The rail and the pane both move people rows on the same rule, so the backend answers it once; the field is optional on the wire so an older backend reads as not live and the hub keeps every pane.
**Approved**: pending

**Decision**: A refusal is a `ProductSiteError` that keeps the backend's code and sentence.
**Rationale**: The pane shows the sentence as the backend wrote it, and a caller that needs to tell a taken handle from a missing base domain reads the code.
**Approved**: pending

**Decision**: A 404 is not retried.
**Rationale**: An ecosystem that is not a product answers it every time, and the All Data pane asks about workspaces, so a retry only doubles the failed requests.
**Approved**: pending

**Decision**: The site answers `subdomainOrigin` beside `primaryOrigin`.
**Rationale**: Once a custom domain is primary the pane still needs the product's own address, to say it still works, to warn what a rename breaks and to show the handle's suffix; the hub does not know the base domain, so it cannot derive it.
**Approved**: pending

**Decision**: Changing or removing a domain invalidates the product site's query.
**Rationale**: The product's address is the site's `primaryOrigin`, which a primary change or a removed primary moves; reading the site again keeps one source for the address.
**Approved**: pending

**Decision**: `productDomainsAvailable` reads a 404 `not_found` as the switch being off.
**Rationale**: The backend hides the routes while `product_custom_domains` is off, so the section hides itself rather than showing an error a manager cannot act on.
**Approved**: pending

**Decision**: The wire types are written by hand in this package rather than taken from the generated API types.
**Rationale**: The module's header says every client in this package does so, following the sets client.
**Approved**: pending

