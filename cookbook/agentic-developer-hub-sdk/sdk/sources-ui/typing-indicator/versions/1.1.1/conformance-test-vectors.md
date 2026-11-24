
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ti-001 | render-dots-pulse-when-inactive | isTyping=false, no words configured | Web: no visual indicator rendered. macOS/iOS: the three dots remain visible at 30% alpha; only the pulse timer is stopped |
| ti-002 | render-dots-pulse-when-active | isTyping=true, no words configured | Three dots animating, cycling through opacity 0.3 → 1.0 on 0.35s cycle |
| ti-003 | show-active-line-while-typing | isTyping=true, words=[{present: "thinking", past: "thought"}] | Glyph animates on 260ms cycle, word "thinking" displays, ellipsis appended |
| ti-004 | cycle-through-status-words | words=[{present: "a", past: "a"}, {present: "b", past: "b"}], labelMs=100 | First render shows word "a"; after 100ms word "b" appears; after 200ms word "a" appears again (no duplicates in between) |
| ti-005 | show-settled-line-when-done | Turn begins and ends, words=[{present: "thinking", past: "thought"}], elapsed=8s | Final render shows "✱ thought for 8s" in `.thinkingDoneText` color, no animation |
| ti-006 | show-idle-phrase-when-configured | idlePhrase="waiting", phase before first turn | Idle phrase renders as "✱ waiting…" in `.thinkingIdleText` color |
| ti-007 | reset-idle-on-first-turn | idlePhrase configured, first isTyping→true transition | Idle phrase disappears and thinking state displays |
| ti-008 | show-utterance-when-provided | utterance="yes!", phase=thinking | Glyph and "yes!" render, overriding status word |
| ti-009 | support-utterance-clear | utterance="yes!" then clearUtterance() called | Thinking state resumes with status word instead of utterance |
| ti-010 | support-colorful-mode | colorful=true, thinking phase | Web: non-green HSL hue applied; color shifts every 1s until done phase reached. macOS: non-green HSL hue applied once at the start of the think; it holds for the rest of the phase and does not shift again until the next fresh think or `say()` |
| ti-011 | not-show-idle-phrase-when-not-configured | No idlePhrase configured, idle phase | No visual indicator rendered |
| ti-012 | announce-status-changes | Phase transitions from idle→thinking→done | Accessibility announcement posted at each transition (thinking, done); no announcement fires on the intervening word rotations |
| ti-013 | respond-to-theme-changes | Component rendered, theme changes | Component repaints with new palette colors immediately |
| ti-014 | handle-empty-frame-array | frames=[], glyph rendering attempted | Empty string rendered as glyph, no crash |
| ti-015 | handle-empty-word-bag | words=[], isTyping=true | Falls back to three-dot pulsing animation |
| ti-016 | maintain-glyph-box-width | Platform with glyph box (macOS), frame changes | Box width remains constant across all frame transitions |
| ti-017 | show-settled-line-when-done, show-utterance-when-provided | utterance="brb" set during thinking phase; isTyping then transitions true→false (turn ends) while the utterance is still set | Web: utterance and glyph continue to display; the settled line does not appear until clearUtterance() is called. macOS/iOS: the shared phase machine settles to done immediately, the settled line replaces "brb", and a subsequent clearUtterance() call is a no-op |
| ti-018 | support-tint-configuration | words configured, tint={color: "#ff0000", applies: "words"}, phase=thinking | Word text renders in the tint color; glyph stays in the default `.personaName` color; once done, the settled line ignores the tint |
| ti-019 | support-frame-interval-configuration | frameMs=100 (web) / frameInterval=.milliseconds(100) (Apple), phase=thinking | Glyph advances to the next frame every 100ms rather than the 260ms default |
| ti-020 | support-word-interval-configuration | labelMs=500 (web) / wordInterval=.milliseconds(500) (Apple), words=[{present: "a", past: "a"}, {present: "b", past: "b"}] | Status word rotates every 500ms rather than the 1800ms default |
| ti-021 | Rapid configuration changes (edge case) | Vocabulary content unchanged but a new array instance is passed mid-turn (same words, new object identity) | The draw-without-replacement bag is NOT rebuilt and the word index is not reset; the current draw order continues uninterrupted |
| ti-022 | Theme palette unavailable (edge case) | Semantic palette cannot be resolved at render time | Component renders using safe fallback (system text) colors and does not crash |
| ti-023 | Idle phrase with no words configured (edge case) | idlePhrase="waiting" configured, words=[] (no vocabulary) | Idle phrase does NOT render; component shows the three-dot fallback path instead |

