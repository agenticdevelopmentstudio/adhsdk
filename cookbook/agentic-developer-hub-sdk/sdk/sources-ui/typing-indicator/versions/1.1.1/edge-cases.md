
- **Null or empty status words**: See **handle-empty-word-bag**. This fallback requires no phase machine to be running.

- **Rapid configuration changes**: If the status word vocabulary is swapped (e.g., persona changes mid-turn), the component MUST rebuild the draw-without-replacement bag immediately and reset the word index. The phase MUST remain unchanged if the active status does not change. Keying on the content of the words array (not its object identity) MUST prevent unnecessary bag rebuilds when the vocabulary is semantically identical but newly created.

- **Concurrent phase machine operations**: The component's phase machine is actor-isolated (Swift) or main-thread-only (UIKit/AppKit/web). Concurrent writes from multiple threads/tasks are not applicable; all operations on the phase machine MUST serialize through the UI thread.

- **Turn transitions during utterance**: On web, if an utterance is set and the turn status changes (isTyping goes false), the component MUST show the utterance until explicitly cleared by the caller (see **show-utterance-when-provided**); the turn ending does not auto-clear utterances. On macOS/iOS, this does not hold: the shared `ThinkingPhase.Machine` settles a showing `.utterance` straight into `.done` on the turn ending (a `nil` status) or drops it to `.thinking` on a fresh non-nil status, clearing `phaseBeforeUtterance` either way. The settled line (or the new thinking content) replaces the utterance immediately, and the caller's subsequent `clearUtterance()` call is a no-op because it guards on `phase == .utterance`.

- **Colorful mode without utterance/thinking**: The `colorful` flag MUST only affect the active (thinking/utterance) phases. During idle or done phases, colorful has no effect.

- **Tint on settled line**: If a tint is configured and the component enters the done phase, the tint MUST NOT be applied to the settled line. The tint only colors the active and utterance phases.

- **Empty frame array**: See **handle-empty-frame-array**. The word text (if any) continues to display normally.

- **Idle phrase with no words configured**: If idlePhrase is set but no words are configured, the idle phrase MUST NOT render. The three-dot fallback path does not support idle phrases.

- **Theme palette unavailable**: If the semantic palette cannot be resolved, the component MUST use safe fallback colors (system text colors). The component MUST NOT crash due to missing theme.

- **Elapsed time calculation at edge**: When the turn settles, elapsed time MUST be calculated as `max(1, round((now - startTime) / 1000))`, ensuring the minimum reported time is 1 second and the result is rounded to the nearest whole second.

