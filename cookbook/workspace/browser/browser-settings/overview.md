
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

Privacy and Security shows three tabs, matching the privacy toolbar's groups: General (storage, scripts, cookies, camera and microphone, protection, site data, history), Events (Pause all events, input, focus and visibility) and Agents (Agent Access, Agent Privacy). Show privacy toolbar is no longer a row; the View menu toggles it. Agent access is two checkboxes over the one three-way setting: Agent access (anything but hidden; turning it on gives full control) and Read only (enabled only while access is on).

The privacy toolbar is three groups, General (Third-Party, Cookies, Hide Images), Events (All Events, Keyboard, Mouse, Tracking, Drag and Drop, Activation) and Agents (Agent, Read Only, Privacy Words, Hide from Agent), each group in a bordered box and each item on a bezel that always shows, spaced evenly across the row, with the Agent view control in a bordered box after them and then, right-justified, a Secrets button (the Secrets window, for the pane's privacy vault; hidden without one) and a gear that opens the pane's privacy settings. The privacy eye leads the row and is green while any privacy setting is in force; in the toolbar it only shows that state, and only in the address bar, where it sits while the toolbar is hidden, does it open the settings (`BrowserPrivacyStatus`, `BrowserPrivacyStripButton`, `BrowserPrivacyStripGroupView`). Each item is a button reading "Title: State" ("Mouse: Off"). A two-valued item toggles its setting in the pane's own settings; Tracking and Third-Party, which have three values, pop up a menu of them, marked with a trailing triangle. An item is green while its privacy protection is in force (Hide Images on, Mouse off, Privacy Words on) and plain otherwise. All Events: Enabled / Disabled is the pane's pause: disabled, every event item shows Off and is disabled, and enabling it again brings back the toggles as they were, since pausing never touches them. Agent is On while access is anything but hidden, and Read Only, enabled only while Agent is on, switches between read only and full control. Where the pane shares a cookie jar, Cookies shows the jar's setting at full strength rather than as a faint disabled button, says why in its tooltip, and a click opens the privacy settings, where Storage gives the tab a jar of its own.

