// @adh-sdk/product-admin — a product's own admin site (phase 6).
//
// It holds what only that site shows: the customer roster and the site's rail. The panes the site
// shares with the hub (roles, sign-up list, sets, totals, the invitation lists) stay in
// @adh-sdk/ecosystem-config and @adh-sdk/ecosystems, mounted with `caller="product_admin"` or
// `hideAdminRecords`, so one pane serves both hosts.
export { ProductUsersPane } from "./ProductUsersPane";
export { PRODUCT_ADMIN_TOPICS, type ProductAdminTopic } from "./product-admin-topics";
