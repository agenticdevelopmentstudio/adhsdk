
This recipe covers the thirteen React hooks in `@adh-sdk/chat`'s
`src/hooks/` directory: `useAllImagesLoaded`, `useBlockCursor`, `useCaretGaze`,
`useCaretTracker` (which also exports the standalone `caretMetrics` function),
`useChatSession`, `useChatSizing`, `useConnectRitual`,
`useInputFocusReclaim`, `useMouseGaze`, `usePersonaGaze`, `usePersonaMood`,
`useRotatingPhrase` (which also exports `useTransientEcho`), and
`useScrollToBottom`. It is a **logic** collection: none of these hooks render
any JSX or own any DOM node. Each one either computes a value from a
caller-supplied `RefObject`/DOM element (measuring, observing, or listening),
or manages timers and state machines that a host component reads and renders
however it likes.

`useChatSession` is the load-bearing member of the set: it adapts either a
legacy `ChatBackend` or a modern contract `Backend` into a `DefaultOrchestrator`
(or adopts a caller-owned orchestrator directly), projects the orchestrator's
view-model into the `ChatMessage[]` shape a transcript renders, and exposes
`sendMessage`/`say`/`sayStream` for driving it. The other twelve hooks are
independent, composable peripherals a chat surface typically needs alongside
that transport: a first-contact "connecting..." ritual (`useConnectRitual`),
caret-following visuals (`useCaretTracker`/`useBlockCursor`/`useCaretGaze`),
attention cues (`useMouseGaze`/`usePersonaGaze`/`usePersonaMood`), layout
(`useChatSizing`/`useScrollToBottom`), input ergonomics
(`useInputFocusReclaim`), copy variety (`useRotatingPhrase`/`useTransientEcho`),
and readiness gating (`useAllImagesLoaded`). None of them import from each
other except `useBlockCursor`, `useCaretGaze`, and `usePersonaGaze`, which are
built on top of `useCaretTracker`/`useMouseGaze`/`useCaretGaze`.

