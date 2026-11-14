
Not applicable: no source file imports Python's `logging` module (or an
equivalent structured, leveled, filterable logging facility). `output.py`'s
`warn`/`die` write directly to the user-facing stderr console as part of the
CLI's own UI (a `[yellow]warn[/yellow]`/`[red]error[/red]`-prefixed line),
not to a logging subsystem — there is no logger name, level, or category to
document in the table this section would otherwise carry.

