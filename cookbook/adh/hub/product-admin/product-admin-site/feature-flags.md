
- **`product_admin_site`**: the backend switch, folded by the backend into the site's `consoleLive` (the switch is on and the product's console is on with a login registration). The pane and the rail never read the switch itself: `consoleLive` false keeps every hub page, and true hides the moved pages. The Product site row is drawn either way.

The Support page depends on the backend's `consented_access` switch, which the page reads only as a 404 on the grants read (see **support-switch-off**); it never reads the switch itself.
