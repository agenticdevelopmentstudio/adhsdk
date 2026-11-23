
This component lets an agent driving a browser pane read the visits the
person allows it to see, and nothing more. It has two parts: a setting,
**Agent can see history**, with three choices — All history, Current tab
only, None — and an agent tool, `browser_history`, that answers according to
the setting in effect for the pane it is called on.

The setting is global and can be overridden per pane, like every other pane
setting. It defaults to **None**: an agent working with privacy on has little
reason to see history, so the person opts in. With *All history* the tool
reads the browser's history store, as the History window shows it. With
*Current tab only* it reads the back/forward list of the tab the agent is
driving, with no store involved. With *None* it refuses and says where the
setting is.

Every title and address the tool returns passes through the agent privacy
gatekeeper's string path before the reply is assembled, so privacy words are
concealed whenever that feature is on — including in an address where the
word appears percent-escaped or with a space written as `+`.

The design is written before the code (design-first, from the more privacy
features design, section 1.4, and its phase 1 plan, Tasks 7 and 10).

