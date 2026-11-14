
- **Null / empty input**: An empty string to `send(_:)` is written as a user message with an empty text block; nothing rejects it. A configuration with no `workingDirectory` cannot be built through the public initializer (the field is a required string); the internal initializer takes an optional one and then passes no current directory.
- **Boundary values**: A stdout line that is valid JSON but not an object, or not JSON, fails to decode and is skipped (MUST). A line of a type the decoder does not know decodes to the `other` kind and is yielded.
- **Concurrent access**: Actor members are serialised. `messages()` is `nonisolated` and guards its hand-out flag with an unfair lock, so two concurrent first calls cannot both receive the live stream.
- **Error states**: A launch failure and a failed or broken-pipe write surface as thrown errors from `start()` and `send(_:)`. A stdout read error is only logged and finishes the stream; a crash is told from a clean end by `standardErrorText()` and by `isRunning`, not by the stream.
- **Offline / disconnected state**: Not applicable: the process is local and the type performs no network access; whether `claude` reaches its service is outside this type.
- **Cancellation**: Cancelling a consumer task does not stop the process. `terminate()` is the way to stop it, and releasing the actor also terminates it; a consumer that breaks out of the stream ends it for good; the pump keeps draining stdout, but its messages are dropped.
- **Process exits on its own**: The stream finishes; `isRunning` becomes false; later `send(_:)` calls fail on the closed pipe.

