
| State | Appearance change |
|-------|------------------|
| Idle | Web: no dots visible (unless idle phrase configured). If idle phrase present: grey done glyph with "waiting" phrase and ellipsis. macOS/iOS (dot fallback): the three dots stay visible at 30% alpha; nothing hides them or the host status row. |
| Thinking | Three dots pulsing (fallback), or animating glyph + rotating status word + ellipsis. Text color is `.personaName` (or tinted/colorful override). |
| Utterance | Animating glyph + caller-provided utterance text (overrides phase). Text color is `.personaName` (or tinted/colorful override). Glyph animates, color cycles if colorful. |
| Done | Web: three dots invisible (fallback), or grey done glyph + past-tense word + "for Ns". macOS/iOS (fallback): dots remain visible, frozen at whichever alpha the last pulse tick left them, since stopping the timer does not hide or reset them. Phase-driven path: grey done glyph + past-tense word + "for Ns". Text color is `.thinkingDoneText` (never tinted or colorful). No animation. |

