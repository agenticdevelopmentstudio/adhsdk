
Not applicable: this component collects no user data. The only
caller-supplied content it holds is the `text` argument to `say(text, now)`,
which it keeps in `SpeechState` in memory for the bubble's own lifetime and
never persists or transmits.

