
The fixture is `top`, a conflict `HEAD` (`ours one`, `ours two`) against `side` (`theirs one`), `middle`, a conflict with a base (`x`, base `y`, `z`), `bottom`, ending with a newline.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-merge-view-001 | merge-side-rows, merge-gutter-numbers, merge-starts | the fixture, no choices | ours `top`, `ours one`, `ours two`, `middle`, `x`, `bottom`; theirs `top`, `theirs one`, a filler, `middle`, `z`, `bottom`; gutters 1-6 and 1, 2, none, 3, 4, 5; sideStarts `[1, 4]`; width 3 |
| git-merge-view-002 | merge-backgrounds, merge-result-rows | the fixture, no choices | conflict rows emphasis on both sides; result `top`, empty emphasis, `middle`, empty emphasis, `bottom`; resultStarts `[1, 3]` |
| git-merge-view-003 | merge-backgrounds, merge-result-rows | theirs, then ours | first conflict added on theirs only, second added on ours only; result `top`, `theirs one`, `middle`, `x`, `bottom`, numbered 1-5 |
| git-merge-view-004 | merge-backgrounds, merge-result-rows | Both, then Base | both sides added on the first; neither on the second; result `top`, `ours one`, `ours two`, `theirs one`, `middle`, `y`, `bottom` |
| git-merge-view-005 | merge-result-rows | four complete sets of choices | result row count equals the resolved text's line count, row texts its lines |
| git-merge-view-006 | merge-syntax | colours per side | each side's rows carry their side's runs; a filler none; result rows the runs of the text they came from |
| git-merge-view-007 | merge-navigation | a long file with two conflicts; Next, Next, Previous | current 1 (`2 of 2`), the sides scrolled to sideStarts[1] and the result to resultStarts[1]; Next stays; back to 0 and its rows |
| git-merge-view-008 | merge-choose | Ours, Theirs, Next, Both | choices `[0: .theirs, 1: .oursThenTheirs]`, rows redrawn |
| git-merge-view-009 | merge-choose | Base on the first conflict, then on the second | disabled and nothing set; then enabled and `[1: .base]` |
| git-merge-view-010 | merge-save | Ours only; Save; then Next, Base, Save | disabled, nothing sent; then `.save(path: "f.txt", text: "top\nours one\nours two\nmiddle\ny\nbottom\n")` |
| git-merge-view-011 | merge-show | choose and move, then `show` again | no choices, conflict 0, the new path |
| git-merge-view-012 | merge-syntax | a Swift conflict with the TextMate fixture | both sides' rows carry coloured runs once the colouring lands |
| git-merge-view-013 | merge-show | `show` the long fixture (first conflict at row 40) before the view is loaded, then load and lay it out at 900×600 | ours and theirs scrolled to `sideStarts[0] × rowHeight`, the result to `resultStarts[0] × rowHeight`; `1 of 2`; Previous disabled, Next enabled |
