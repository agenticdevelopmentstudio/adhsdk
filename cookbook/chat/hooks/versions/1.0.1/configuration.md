
Every one of these hooks is configured entirely through typed function
arguments — there are no environment variables, settings keys, feature
flags, or persisted files involved anywhere in this source.

| Hook | Option | Type | Default | Description |
|------|--------|------|---------|-------------|
| `useChatSession` | `backend` | `ChatBackend \| Backend` | — | Legacy or contract backend; required unless `orchestrator` is given |
| `useChatSession` | `orchestrator` | `Orchestrator` | — | A caller-owned orchestrator to adopt instead of building one |
| `useChatSession` | `persona` | `Partial<ChatParticipant>` | `{}` (persona ID `'persona'`) | Persona participant identity |
| `useChatSession` | `user` | `Partial<ChatParticipant>` | `{name:'You', avatar:'Y'}` | Local user participant identity |
| `useChatSession` | `welcomeMessage` | `string` | none | Initial persona message delivered before `start()`; ignored when adopting an orchestrator |
| `useConnectRitual` | `say` | `(text: string) => Promise<void>` | — | Required; delivers a line into the transcript |
| `useConnectRitual` | `welcome` / `greeting` | `string` | — | Required lines spoken during the ritual |
| `useConnectRitual` | `connectingLine` / `connectedLine` | `string` | — | Required status-line text |
| `useConnectRitual` | `waitLines` / `stallLines` | `string[]` | `[]` | Status-line cadence content before/after the primary wait sequence |
| `useConnectRitual` | `engageOn` | `'pointer' \| 'mount' \| RefObject` | `'pointer'` | What triggers engagement |
| `useConnectRitual` | `readyAfterMs` | `number` | `2000` | Delay before a pointer move can engage (pointer mode only) |
| `useConnectRitual` | `giveUpAfterMs` | `number` | `30000` | Auto-engage timeout (pointer mode only) |
| `useConnectRitual` | `greetDelayMs` | `number` | `800` | Pause between `welcome` and `greeting` |
| `useConnectRitual` | `waitStepMs` / `stallStepMs` | `number` | `900` / `1600` | Status-line stepping cadence |
| `useChatSizing` | `sizing.active` | `InlineChatSizing['active']` | `{mode:'fixed'}` | Behavior while engaged (or always, without `inactive`) |
| `useChatSizing` | `sizing.inactive` | `InlineChatSizing['active']` | none | Behavior while disengaged; its presence enables engagement tracking |
| `useChatSizing` | `sizing.transition` | `'animated' \| 'none'` | `'animated'` | Whether the `pc-anim` class is applied |
| `useScrollToBottom` | `ref` | `RefObject<HTMLElement>` | — | The scrollable transcript container |
| `useScrollToBottom` | `deps` | `unknown[]` | — | Dependency array that also triggers a same-frame bottom check |
| `useAllImagesLoaded` | `content` | `ContentItem[]` | `[]` | Rich-content items; only `type:'image'` entries are watched |
| `useCaretTracker` | `wrapperRef` | `RefObject<HTMLElement>` | — | Container searched for the input via `selector` |
| `useCaretTracker` | `enabled` | `boolean` | — | Whether tracking is active |
| `useCaretTracker` | `onMeasure` | `(input: HTMLInputElement \| null) => void` | — | Reports the focused input, or `null` |
| `useCaretTracker` | `selector` | `string` | `CHAT_INPUT_SELECTOR` (`'.pc-input'`) | CSS selector for the input |
| `useBlockCursor` | `resetKey` | `unknown` | — | Value whose change forces a re-measure while focused |
| `useCaretGaze` | `downBias` | `number` | `0.9` | Fixed `y` reported for caret-driven gaze |
| `useCaretGaze` | `selector` | `string` | `CHAT_INPUT_SELECTOR` | CSS selector for the input |
| `useMouseGaze` | `anchorRef` | `RefObject<HTMLElement>` | — | Element whose center is the gaze origin |
| `useMouseGaze` | `enabled` | `boolean` | — | Whether the `pointermove` listener is installed |
| `usePersonaMood` | `responding` / `composing` | `boolean` | — | Engagement inputs; `responding` takes priority |
| `usePersonaMood` | `flightMoods` / `typingMoods` | `E[]` | — | Mood pools rotated while responding/composing |
| `usePersonaMood` | `answerBeat` | `{mood: E, ms: number}` | none | Optional one-shot mood shown when `responding` ends |
| `usePersonaMood` | `cycleMs` | `number` | `1500` | Mood rotation interval |
| `useRotatingPhrase` | `pool` | `readonly string[]` | — | Candidate phrases |
| `useRotatingPhrase` | `rerollKey` | `number` | — | Value whose change triggers a re-roll |
| `useTransientEcho` | `utterance` | `{text: string, id: number} \| null \| undefined` | — | The utterance to echo |
| `useTransientEcho` | `holdMs` | `number` | `1800` | How long the echo persists before clearing |
| `useInputFocusReclaim` | `wrapperRef` | `RefObject<HTMLElement>` | — | Container used for the outside-click guard |
| `useInputFocusReclaim` | `enabled` | `boolean` | — | Whether reclaim is active |
| `useInputFocusReclaim` | `selector` | `string` | `CHAT_INPUT_SELECTOR` | CSS selector for the input |

