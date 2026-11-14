
| State | Appearance change |
|-------|------------------|
| Default (identity words) | Terminal text appears exactly as the shell printed it; nothing is held. |
| Words set | Real words in output appear as their aliases; aliases typed or pasted reach the shell as the real text. |
| Holding output | A run that could still become a real word is not yet drawn; it is drawn as it stands after 0.15 seconds without further output, or as the alias when the word completes. |
| Holding input | A typed run that could still become an alias is not yet sent to the shell, and no timer releases it. |
| Words changed | Held input and held output are released under the old words, then new words apply from the next byte. |
| Pressed | Not applicable: the class adds no pointer or press handling. |
| Disabled | Not applicable: the class has no enabled flag. |
| Focused | Not applicable: caret and focus behavior come from the inherited themed view and are not overridden. |
| Loading | Not applicable: the class shows no loading indication; the session, not the view, waits for its first words before it starts the shell. |

