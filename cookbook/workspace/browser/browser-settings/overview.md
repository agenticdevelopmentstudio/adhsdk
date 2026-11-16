
The web browser's settings are one container of topics, shown in the app's
Settings window and, scoped to one pane, in that pane's settings sheet. This
ingredient fixes which topics exist, in what order, and which control lives in
each. The topics say what they hold: **General**, **Behavior**,
**Appearance**, **Privacy and Security**, **Downloads**, **Extensions** and
**Reset**, with the Chrome engine's topics between Extensions and Reset when
that engine is compiled in. The old History, Cookies, Media and Permissions
and Safari topics are gone; their controls moved into the topics above.

A setting key is a storage format: moving a control between topics changes
its group, never its key, so nobody's stored value is orphaned. Two things
are new rather than moved: a **Manage Site Data…** window that holds the site
data table the Safari topic used to show inline, and an **Agent can see
history** choice (All history, Current tab only, None; default None), global
and overridable per pane, which gates the agent's `browser_history` tool.
History recording also gains a rule: nothing is recorded while private
browsing is on for the pane. Sidebar search keeps finding every control
because each topic's search keywords move with its controls.

