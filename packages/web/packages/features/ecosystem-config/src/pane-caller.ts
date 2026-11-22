/**
 * Who is editing through one of this package's product panes: a workspace manager in the hub, or a
 * product admin on the product's own admin site (phase 6). The panes default to `manager`; the
 * admin site passes `product_admin`, and a pane narrows only what the backend would refuse that
 * caller anyway.
 */
export type PaneCaller = "manager" | "product_admin";
