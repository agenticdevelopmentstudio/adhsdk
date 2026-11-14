
ProfileInfoButton is a small circled "i" that sits on the chat frame's top border, just past the rounded top-left corner, and links to the persona's profile (for example its Agentic Persona Registry page). It is a plain link, not a button: it navigates, it holds no state, and it opens the profile in a new tab.

The host renders it as a sibling of the chat view, inside the host's `position: relative` wrapper. It is not rendered inside the `.persona-chat` element, because the component's own comment says that element's `overflow: hidden` would clip the half of the circle that hangs over the top edge (`base.css` sets `.persona-chat` to `overflow: visible`, while modes such as `.pc-mobile-overlay` set it to `hidden`). The host also imports the opt-in stylesheet `css/components/profile-info.css` (`BitbagChat` documents importing it as `css/chat/components/profile-info.css` from `@adh-sdk/persona`, which re-imports the chat package's file); the component ships no styling of its own. Colors come from the chat theme's own tokens, so the button reads as part of whichever theme the chat wears. It is exported from the chat package together with its `ProfileInfoButtonProps` type, and `BitbagChat` renders it only when it has a profile URL.

Inputs:

| Prop | Type | Required | Meaning |
|------|------|----------|---------|
| `profileUrl` | string | yes | The persona's profile URL; opens in a new tab. |
| `label` | string | yes | Accessible name and hover tooltip (for example "olylo's profile"). |
| `className` | string | no | Extra class name appended after the component's own class. |

