
Theme `name` and `attribution` values are proper nouns and credits written as hardcoded string literals (including the accented "Rosé Pine"), and the source has no string table or localized lookup. That is why `no-hardcoded-strings` is `partial` in Compliance: the strings are not translated, and no catalogue exists to translate them from. The Unicode character in "Rosé Pine" is stored as ordinary UTF-8 in the Swift source.

