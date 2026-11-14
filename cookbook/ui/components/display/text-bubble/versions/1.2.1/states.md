
| State | Behavior |
|---|---|
| Inactive (`active === false`) | plain, un-split text; no animation |
| Active — idle hold | during the leading/`pauseMs` window each cycle, glyphs are cleared to plain |
| Active — sweeping | lens glides along glyph centres; in-lens glyphs scale/blur/shift |
| Loop restart | at the end of a sweep the lens returns to the start (after `pauseMs`) |
| Cursive script text | left rendered normally; effect disabled for that string |
| Empty / whitespace-only text | no spans built; nothing animates |
| Cleanup / `resetKey` change | original plain text restored; element remounted on `resetKey` |

