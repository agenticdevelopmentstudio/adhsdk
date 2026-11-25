
The decoder has two states, accumulating and flushed; the plugin itself is stateless.

| State | Entered when | Behavior |
|-------|-------------|----------|
| accumulating | The decoder is created | Text deltas from the wrapped decoder are appended to the reply and nothing is emitted; native tool-use events pass through. |
| flushed | The wrapped decoder reports the end, or `finish()` runs without one | The prose, calls and end event have been emitted once; later ends are dropped. |

