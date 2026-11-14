
- **Null / empty input**: A send or a read of zero bytes forwards nothing when the stream releases nothing, and with nothing held does not arm a timer (MUST). Empty words behave as a pass-through (MUST).
- **Boundary values**: A word split at every byte position across sends or reads is still replaced once; the held run is shorter than the longest word (MUST). A change of words while nothing is held flushes empty arrays and forwards nothing (MUST).
- **Concurrent access**: The view and both streams are main-actor only; the streams are values with no locking (MUST). The timer fires on the thread that armed it, which is the main thread, because the view is main-actor.
- **Error states**: No operation throws or reports an error. Invalid UTF-8 passes through unchanged because the streams work on bytes (MUST).
- **Offline / disconnected state**: Not applicable: the view performs no network access; it sits between the engine and a local process.
- **Held input that is never completed**: A partial alias typed and left alone stays held; no timer releases it and only the next send, a divergence, a completion or a change of words does (MUST, per `input-no-timer`). The user sees no echo of the held characters because the shell has not received them.
- **Held output at a prompt**: A prompt ending in a prefix of a real word appears after 0.15 seconds (MUST), then the remainder of a later read is rescanned from the start of the new bytes, so a word split across a flush is shown as typed.
- **Words changed mid-hold**: Bytes held under the old words come out unchanged or replaced under the old words, never under the new words (MUST).
- **Terminal replies**: A reply the terminal sends to a query goes through the same input stream, so an alias in a reply is revealed (MUST, per `send-single-choke-point`).
- **Equal words set again**: Ignored, including when the pairs are the same in the same order (MUST).
- **Timer outliving the view**: The timer holds the view for at most 0.15 seconds, so the view is released within that time of its last read (MUST).
- **Screen reader**: The view reports itself empty to assistive technology (MUST); see the open question on `screen-reader-alternative`.

