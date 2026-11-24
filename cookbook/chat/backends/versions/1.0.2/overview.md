
`packages/web/packages/chat/src/backends/` is the chat package's transport
layer: seven files defining two conversation-transport interfaces and the
concrete classes that implement them.

- **`types.ts`** declares `ChatBackend`, the package's original, web-only
  transport interface: `sendMessage` (required), `sendMessageStream`
  (optional, preferred when present), and `destroy` (optional).
- **`../contract/backend/Backend.ts`** (outside this directory, but the
  interface every class here ultimately targets) declares the portable,
  cross-platform `Backend` contract: `send`, `setLocalTyping`,
  `submitWidgetResponse`, and a push-based `inboundEvents: AsyncIterable<InboundEvent>`.
- **`EventQueue.ts`** is the single-consumer async push queue every `Backend`
  implementation here uses to back `inboundEvents`.
- **`FetchBackend.ts`** and **`MockBackend.ts`** implement `ChatBackend`
  directly: an HTTP JSON POST transport and a canned-response transport for
  demos and tests, respectively.
- **`ShuffleBag.ts`** exports `ShuffleBag`, a general-purpose shuffle-bag
  utility, and `streamTokens`, a token-by-token text-streaming generator —
  both exported from the package for building custom `ChatBackend`s (in
  practice, `MockBackend`-style implementations that want to look like they
  are typing).
- **`ChatBackendAdapter.ts`** implements `Backend` by wrapping any
  `ChatBackend`, translating its `ChatStreamEvent`s (or its unary
  `ChatResponse`) into `InboundEvent`s.
- **`PersonaChatBackend.ts`** implements `Backend` directly against adh's
  Server-Sent-Events chat API, with no `ChatBackend` in between. It is the
  reference implementation of the separate `persona-chat-coordinator`
  ingredient spec (`docs/specs/ingredients/persona-chat-coordinator.md`); see
  `related` above.

The package's only consumer of this directory, `hooks/useChatSession.ts`,
accepts `backend?: ChatBackend | Backend`, narrows with a `'inboundEvents' in
backend` type guard (`isContractBackend`), and wraps a raw `ChatBackend` in a
`ChatBackendAdapter` before handing it to the orchestrator — so every backend
the rest of the package deals with is, in the end, a `Backend`.

