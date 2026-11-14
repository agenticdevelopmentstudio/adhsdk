
| State | Behavior |
|---|---|
| Inactive (`active === false`) | plain, un-split text; no animation |
| Active — idle hold | during the `pauseMs` window at the start of each cycle, glyphs are cleared to plain; with `pauseMs` of 0 there is no hold and the first sweep starts immediately |
| Active — sweeping | lens glides along glyph centres; in-lens glyphs scale/blur/shift |
| Loop restart | at the end of a sweep the lens returns to the start (after `pauseMs`) |
| Cursive script text | left rendered normally; effect disabled for that string |
| Empty / whitespace-only text | no spans built; nothing animates |
| Cleanup / `resetKey` change | original plain text restored; element remounted on `resetKey` |

