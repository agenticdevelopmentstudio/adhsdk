
This component makes the user's "Hide distracting items" list take effect
on the page. For the page a browser pane shows, it asks the hidden-items
store for the user list's enabled selectors and puts one style element,
`__adk_hidden_items`, into the page, holding one
`<selector> { display: none !important; }` rule per selector. The style
goes in at document start, so a matching item is never drawn on a fresh
load, and it is re-applied to the live page whenever the store changes and
on every navigation, so toggling an entry in the popover takes effect at
once. Because they are style rules, they also hide matching content the
page adds later, with no observer.

Each rule is added on its own, so one selector the engine rejects is
skipped and never disables the others. Selectors reach the page's script
as a JSON array, never pasted into script text, since a selector is
user-picked data that can contain quotes.

A second, temporary rule set, `__adk_hidden_items_preview`, serves the
picker dialog's "Show page with selected element removed" checkbox: it
hides the element being considered until the dialog closes, without saving
anything.

The engine has a single owner for its user scripts, and this style script
is added there with the others. A side effect is intended: the agent
gatekeeper's walker skips `display: none` content, so whatever the user
hides from themselves is hidden from the agent too.

