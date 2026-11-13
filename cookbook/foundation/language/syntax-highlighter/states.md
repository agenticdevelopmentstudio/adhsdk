
- **No engine**: before the first highlight that reaches the engine; nothing is loaded.
- **Ready**: after the bundle is evaluated and `create` has resolved; grammars load on first use and stay cached in the bundle.
- A failed `create` leaves the actor without an engine; the next call tries again.

