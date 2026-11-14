
The status words, idle phrase, and utterance text are caller-provided and are localized by the caller's data layer, not by this component. The text the component itself renders around them, however, is not caller-controlled and is currently hardcoded rather than externalized:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| thinking-ellipsis | `…` | Appended after the active status word or idle phrase (web: `.pc-thinking-ellipsis`; Apple: appended directly to the label text). |
| settled-for | `for` | Connector in the settled line, e.g. "thought for 8s" (web: `.pc-thinking-for`; Apple: `"\(word) for \(machine.elapsedSeconds)s"`). |
| settled-seconds-suffix | `s` | Unit suffix appended to the elapsed-second count in the settled line. |

These three strings are literals in `TypingIndicator.tsx`, `ThinkingIndicatorView.swift`, and `MobileThinkingIndicatorView.swift`, and the elapsed-second count is rendered through a fixed `"for {n}s"` template rather than a locale-aware or pluralizable formatter (see the Compliance section's `locale-aware-formatting` and `no-hardcoded-strings` checks below).

