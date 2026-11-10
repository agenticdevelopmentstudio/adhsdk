
The component owns three hardcoded English strings — the flavor labels `"Help"`, `"Information"`, and `"What's new"` defined in the `FLAVORS` table. These are not rendered as visible on-screen text, but they do reach assistive technology through the popover panel's accessible name, so they are user-facing in that sense. They are not currently externalized to a localization system. `entry.title` and `entry.body` are caller-supplied content; localizing that content is the caller's responsibility.

