
- **`product_admin_site`**: the backend switch, read as `enabled` from the admin site answer. Off hides the Admin site row; on shows it, and with a site hides the moved pages.

The Support page depends on the backend's `consented_access` switch, which the page reads only as a 404 on the grants read (see **support-switch-off**); it never reads the switch itself.
