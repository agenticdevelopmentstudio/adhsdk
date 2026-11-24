
Every visible string — "Backend deploying", "Backend unreachable", both subtitles, "Retrying in {countdown}s" and "Try again now" — is a hard-coded English literal in the component. The source defines no string keys, no message catalogue and no locale parameter, so there is no key table to fill; translating the component means changing those literals in source. This fails the `no-hardcoded-strings` compliance check (see Compliance).

