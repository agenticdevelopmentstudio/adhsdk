
Quoting for a POSIX shell, so a word reaches the command as exactly one argument whatever it holds. The spelling matches Python's `shlex.quote`, so the Python helpers and this code write identical strings for the same path in a shared configuration file (the type doc comment, lines 3-6 of `Core/Process/ShellQuoting.swift`). `ShellQuoting` is a caseless `enum` of three static functions: `quote(_:)` always quotes, `quoteIfNeeded(_:)` leaves a plain word readable, and `commandLine(_:)` joins words into one command line.

