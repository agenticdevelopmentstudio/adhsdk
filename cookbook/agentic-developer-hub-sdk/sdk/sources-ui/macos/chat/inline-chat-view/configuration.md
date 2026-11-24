
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` / `viewModel` | ChatSession / ChatViewModel | required | Active chat session or view model binding |
| `sizing` | InlineChatSizing | `{ active: { mode: 'fixed' } }` | Size behavior active/inactive and transition. Default `fixed` height: web inherits the surrounding CSS (today `.pc-inline` at 50vh, capped at 600px); Apple floors at `>= 200pt` (`defaultTranscriptHeight`). |
| `placeholder` | string | none | Placeholder text in input field |
| `thinkingLabels` | StatusWordPair[] | dots | Custom words and icons for thinking indicator phases |
| `thinkingFrames` | string[] | none | Glyph frames for rotating thinking animation |
| `thinkingDoneGlyph` | string | none | Settled glyph shown after thinking completes |
| `thinkingColorful` | boolean | false | Rotate through random non-green colors while thinking (Apple) |
| `thinkingTint` | StatusTintSpec | none | Which elements (glyph/words/both) are tinted |
| `statusWhileStreaming` | boolean | false | Keep thinking indicator animating during reply stream |
| `idlePhrase` | string | none | Status text shown when no remote activity |
| `statusUtterance` | string \| null | none | Transient status override (takes precedence) |
| `inputDisabled` | boolean | false | Render input but block typing and sending |
| `fadeOlder` | boolean | false | Dim older messages proportionally (web only) |
| `chrome` | InlineChatChrome | defaults | Prompt glyph, send glyph, divider, caret style, border, corner radius, placeholder (Apple) |
| `blinksCaret` | boolean | true | Block caret blinks or stays solid (Apple) |
| `backdrop` | NSView | none | Optional animated or static backdrop (Apple) |
| `showsBackdrop` | boolean | true | Backdrop visibility toggle (Apple) |
| `surfaceTransparency` | number | 0 | Surface opacity reduction 0–100% (Apple) |
| `onTextScaleNudge` | (Int) → Void | none | Callback for ⌘+/−/0 text scale adjustments (Apple) |
| `localParticipantID` | string | required | Participant ID for local user to determine bubble side (Apple) |
| `viewModel.commandActivity` | [CommandActivity] | (view-model state) | Tool invocations rendered as `ToolCallPillView` rows below the transcript (Apple) |
| Bubble side (web) | — | — | Not exposed as a prop on `InlineChat`/`InlineChatView`; which side a message renders on is delegated to the `Transcript` component ([adhsdk.ingredient.chat.components.transcript](cookbook:98e78d31-2c3a-47dc-a156-435a5732a29f)), which this recipe does not define |

