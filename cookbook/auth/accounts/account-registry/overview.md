
`AccountRegistry` is the list of accounts an app offers, kept in display order. An accounts UI renders one entry per account in `accounts` and observes the registry through a single `onChange` closure. Each entry is an `Account`: a reference-type protocol (`AnyObject`) with a stable `id`. The registry is a plain `@MainActor` class in the Foundation-only SDK tier. It does no I/O and never calls an account's own methods. Its source comment says `add` and `remove` exist so the panel's plus and minus controls can be enabled later without touching `Account`.

