
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `FetchBackendOptions.url` | `string` | required | Endpoint `FetchBackend` POSTs to. |
| `FetchBackendOptions.headers` | `Record<string, string>` | `{}` (merged under `'Content-Type': 'application/json'`) | Extra/overriding request headers. |
| `FetchBackendOptions.mapResponse` | `(data: unknown) => ChatResponse` | `(data) => (data as { reply: string }).reply` | Maps the parsed JSON body to a `ChatResponse`. |
| `MockBackendOptions.responses` | `ResponseMap` | `{}` (merged over `DEFAULT_RESPONSES`) | Additional or overriding canned responses, keyed by lowercased/trimmed input text. |
| `MockBackendOptions.delayMs` | `number \| [min: number, max: number]` | `[400, 1200]` | Simulated response latency. |
| `ChatBackendAdapterOptions.personaID` | `string` | required | Sender id stamped on every emitted event and committed message. |
| `ChatBackendAdapterOptions.history` | `() => ChatMessage[]` | required | Caller-supplied accessor for the transcript as `ChatBackend.sendMessage`/`sendMessageStream` expect it, read once per `send` call. |
| `PersonaChatBackendOptions.personaSlug` | `string` | required | Persona adh resolves the conversation against. |
| `PersonaChatBackendOptions.model` | `string \| null` | `undefined` (adh uses the persona's configured model) | Overrides the persona's configured model when set. |
| `PersonaChatBackendOptions.baseURL` | `string` | `/api` | Root of the adh chat API; conversations live at `${baseURL}/chat/conversations`. |
| `PersonaChatBackendOptions.authorize` | `(path: string, init: RequestInit) => Promise<Response>` | required | Host-injected, credential-attaching fetch wrapper; `PersonaChatBackend` never handles credentials itself. |
| `PersonaChatBackendOptions.onStatus` | `(status: TurnStatus \| null) => void` | `undefined` | Receives out-of-band turn-phase transitions (`'thinking' \| 'responding' \| 'retrying' \| null`). |
| `PersonaChatBackendOptions.participantID` | `string` | `personaSlug` | Sender id stamped on emitted events, when different from the persona's resolution slug. |
| `ShuffleBag` constructor arg | `readonly T[]` | required | The item set to draw from; MUST be non-empty (**shufflebag-nonempty-construction**). |
| `StreamTokensOptions.minMs` | `number` | `45` | Floor delay between emitted tokens. |
| `StreamTokensOptions.jitterMs` | `number` | `55` | Additional random delay (uniform `[0, jitterMs)`) added to `minMs`. |

