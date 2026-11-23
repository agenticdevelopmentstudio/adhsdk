
This component keeps the web browser's hidden-item lists. There are two
lists with the same shape, kept apart: the **user list** ("Hide distracting
items"), which holds what the user does not want to see, and the **agent
list** ("Hide elements from agent"), which holds what an agent must not
receive. Each entry names a site (a site pattern, by default the page's host
and every path under it), a CSS selector, whether the selector picks one
item or all items like it, a short human label captured when the item was
picked, whether the entry is enabled, and when it was created. An entry
applies site-wide: to every page whose address matches its site pattern.

Per site, the user list also has a "Hide distracting items" switch, on by
default, that turns the whole user list off for that site without deleting
any entry. The agent list has no such switch.

The store's main question is "which selectors are in force on this page for
this list", which the rendering of the user list and the agent gatekeeper
both ask. It announces every change so a page showing can be brought up to
date. Everything lives in its own SQLite file, `BrowserHiddenItems.db`, in
the app's home directory, which follows the test home override so a scratch
run never touches the real lists.

