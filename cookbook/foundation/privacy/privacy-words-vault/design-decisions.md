
**Decision**: Reading the words to run a terminal never prompts, while seeing them does.
**Rationale**: The source says a private terminal must conceal from its first byte, so starting one must not ask; what stands between the words and someone else at the keyboard is the authentication on showing, opening and saving.
**Approved**: pending

**Decision**: Authentication success is never remembered; every `authenticate` call prompts and re-reads.
**Rationale**: The source says this is the barrier against another person at the keyboard; re-reading also protects an editor opened here from writing back a list that predates another app's save.
**Approved**: pending

**Decision**: Words still saved under the old `userPresence` guard are upgraded by one prompt, shared by terminals starting together.
**Rationale**: Reading and saving again without the guard means no later start asks; the shared upgrade task stops several terminals stacking prompts, and the prompt text says it is asked once.
**Approved**: pending

**Decision**: Each app keeps its own vault and announces saves with a distributed notification naming no words.
**Rationale**: The source says an edit in one app conceals in all of them; the notification leaks nothing, and a vault that never loaded has nothing to refresh, so only loaded vaults re-read.
**Approved**: pending

**Decision**: A vault ignores notifications carrying its own process identifier.
**Rationale**: Its own save already set the filter; the tag also means a second vault in the same process does not refresh from it.
**Approved**: pending

**Decision**: What a vault does when the reload after another app's save fails: keep the stale filter (today, silently), drop the filter, publish an error, or log it.
**Rationale**: The source discards the error with `try?` and keeps concealing with the old words, which another app has already replaced; which behavior is right is not settled, so the requirement stays marked until it is.
**Approved**: pending
