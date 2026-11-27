
- **A workspace asked about (MUST)**: the All Data pane asks about a workspace's ecosystem too, which is not a product and answers 404; the hook asks once and the pane reads the failure as "not gated".
- **No base domain (MUST)**: a backend with no product sites base domain answers `primaryOrigin: null`; the row keeps the handle and the caller says the address is not configured.
- **A change that conflicts (MUST)**: the 409 reaches the caller as a `ProductSiteError`, carrying the backend's code and sentence, and the cached site is not touched.

