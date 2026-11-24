
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

Notes: separation-of-concerns passes because `GitRepoScanner.swift` does
exactly one thing — walk the filesystem and classify directories — and
delegates no UI or presentation concern to itself; policy above it
(reconciling scan results against known projects, presenting a settings
panel) lives in other files entirely. unit-test-coverage passes because
`GitRepoScannerTests.swift` exercises repository detection, every skip rule
(hidden, pruned, root-level pattern, symlink), pattern case-folding,
multi-root and empty-tree scans, cancellation, progress reporting, result
ordering, and all three `originRemote` branches. explicit-error-handling
fails because the `contentsOfDirectory` catch block
discards the thrown error completely — no log, no return value, no
`Progress` field — which is exactly the "silently swallowed" case the check
prohibits; this is the same gap recorded as
`unreadable-directory-error-visibility`. fault-tolerance passes because
every other form of unpredictable filesystem state this file encounters —
missing `HEAD`, a `.git` file instead of a directory, an unparseable or
missing `config`, a symlink cycle — is handled without a crash, via `try?`
and explicit case checks rather than by assuming well-formed input.
data-integrity is partial because a `.git/config` that is present but
corrupt (invalid UTF-8, or malformed INI text past the point the manual
parser expects) is treated identically to a config with no origin
configured — both yield `nil` from `originRemote(inGitDirectory:)` — so
corrupt data is never detected as corrupt or reported as such, only ever
observed as "no remote."

