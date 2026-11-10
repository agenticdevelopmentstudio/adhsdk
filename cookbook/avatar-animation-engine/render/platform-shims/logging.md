
Not applicable: neither file calls a logger, `print`, `os_log`, or
`console.*`. Failures are communicated only through return values (`nil` from
`avatarInk`, a thrown error from `avatarItem`) to the caller.

