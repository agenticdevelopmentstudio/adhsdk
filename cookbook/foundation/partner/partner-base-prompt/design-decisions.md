
**Decision**: The base prompt tells the partner to raise an attention item rather than wait or write to the transcript.
**Rationale**: The partner runs only when a message arrives and the owner does not look in the transcript for waiting work; the Needs-you pane lists attention items, so that is the one place the owner is told to look.
**Approved**: pending

**Decision**: Git is read-only for the partner and `--output` is forbidden.
**Rationale**: The source states `--output` writes a file, and that the partner never changes the owner's branches, commits or working trees; the code-review sessions it opens work in their own worktrees.
**Approved**: pending

**Decision**: Only the code-reviews job's steps carry a note that they arrive filled in from `partner_review_start`.
**Rationale**: That job's step commands hold placeholders that the tool fills per review; the note keeps the partner from running the unfilled template. Other jobs' placeholders are filled by the partner from the job's work, per the base text.
**Approved**: pending

**Decision**: The skill description escapes the job name, but the skill `name` uses the job id unescaped.
**Rationale**: Names are free text from the owner and could break the quoted YAML string, so the source escapes them (a test covers quotes and backslashes). Ids are identifiers that the source treats as safe, and built-in ids are plain, but nothing enforces that.
**Approved**: pending

**Decision**: The base text lists the tools in a table inside the prompt text, and a test checks each name is present.
**Rationale**: The partner can call only the tools it is told about. The test checks that each listed name appears in the text, which catches a tool dropped from the table but not a new tool that was never added to it.
**Approved**: pending


**Decision**: A step's name, command and condition are inserted without escaping, and a command that contains a backtick can end its code span early.
**Rationale**: Step commands are written by the owner for the partner to read, not rendered as markdown for anyone else, and the partner reads the line as text; guarding against a backtick would need a longer code fence that the source does not use. The risk is accepted.
**Approved**: pending
