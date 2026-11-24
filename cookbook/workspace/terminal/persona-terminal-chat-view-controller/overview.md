
`PersonaTerminalChatViewController` is a chat pane with an AI persona that can
work the user's terminal. It never touches the terminal directly: it reaches it
by way of the Terminal Chat in the same tab ("the Terminal Chat" is the first
one in that tab). When that Terminal Chat is connected to a private terminal,
the persona only ever sees the terminal's privacy words, never the real ones
(the source's description of the Terminal Chat's behavior; the masking is not
done in this file).

The persona runs on one of the LLM providers configured in Settings, chosen per
pane along with a model and the persona's instructions. The source calls the
feature experimental and deliberately narrow, like the Terminal Chat itself.

The controller:

- builds a `LocalChatSession` whose plugin, context and tools are looked up at
  the moment of each turn, so a change in the pane's settings applies to the next
  message with no rebuild;
- shows a `ChatView` filling a 360 by 500 themed container, with a status line
  that says why the chat cannot yet work;
- offers four rows in the pane's options sheet (connect toggle, LLM provider,
  model, persona) through `PaneOptionsProviding`, and stores the choices in the
  pane's state store;
- cancels its model fetch and closes its session when the pane is discarded.

The chat view, session, view model, plugin manager, provider resolver and the
Terminal Chat are other components; this recipe covers the wiring, the
settings and the status logic in this controller.

