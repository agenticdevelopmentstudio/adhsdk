
The repository has no test that names `PrivateTerminalView`. The vectors are derived from the source. Unless stated, the words are one pair, alias `robin` and real `mike`; "send" means a call to the send entry point with ASCII bytes and "receive" means a call to the data-received entry point; the engine's observed input is what reaches the shell and its observed parser input is what is drawn.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| private-terminal-view-001 | substitutions-property, identity-passthrough | New view, no words set; send `ls`, receive `hello mike` | The shell gets `ls`; the parser gets `hello mike`; nothing held. |
| private-terminal-view-002 | send-reveals, send-single-choke-point | Words set; send `cd robin` | The shell gets `cd mike`. |
| private-terminal-view-003 | receive-conceals, conceal-before-parse | Words set; receive `hi mike` | The parser gets `hi robin`; the buffer holds `robin`. |
| private-terminal-view-004 | send-holds-partial, send-nothing-when-empty | Words set; send `rob` | No send reaches the shell; the input stream is holding. |
| private-terminal-view-005 | send-holds-partial | After vector 004, send `in` | The shell gets `mike`. |
| private-terminal-view-006 | receive-holds-partial, receive-nothing-when-empty | Words set; receive `mik` | The parser is not called with those bytes; the output stream is holding. |
| private-terminal-view-007 | output-quiet-flush | After vector 006, wait 0.15 seconds with no further read | The parser gets `mik`. |
| private-terminal-view-008 | output-timer-rearm | Words set; receive `mik`, then 0.1 seconds later receive `e` | The first timer is cancelled; the parser gets `robin` at once; no timer is pending. |
| private-terminal-view-009 | output-timer-rearm | Words set; receive `mi`, then 0.1 seconds later receive `k` | The first timer is cancelled and a new one is armed; the parser gets `mik` only after 0.15 seconds from the second read. |
| private-terminal-view-010 | input-no-timer | Words set; send `rob`; wait 5 seconds | Nothing reaches the shell. |
| private-terminal-view-011 | replace-words-flush, replace-words-send-pending | Words set; send `rob`; set `substitutions` to a different filter | The shell gets `rob`; both streams are rebuilt. |
| private-terminal-view-012 | replace-words-flush, replace-words-show-pending | Words set; receive `mik`; set `substitutions` to a different filter | The parser gets `mik`. |
| private-terminal-view-013 | equal-words-ignored | Words set; send `rob`; set `substitutions` to an equal filter | Nothing is flushed; the input stream is still holding `rob`. |
| private-terminal-view-014 | replace-words-new-streams | Words set to pair one; then set to a filter with alias `sam` and real `lee`; send `sam` | The shell gets `lee`; the first pair no longer applies. |
| private-terminal-view-015 | accessibility-hidden | Query the view's accessibility element flag, role, value, selected text and children | False, nil, nil, nil and an empty list. |
| private-terminal-view-016 | output-flush-does-not-rearm | After the quiet flush in vector 007 | No timer is pending and a further read starts the cycle again. |
| private-terminal-view-017 | no-errors | Receive bytes 0xFF 0x6D with words set | No error; 0xFF reaches the parser and `m` is held. |

