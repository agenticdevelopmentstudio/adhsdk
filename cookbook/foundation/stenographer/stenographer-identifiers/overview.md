
`StenographerIdentifiers` and `StenographerPaths` are the single spelling of every name the Stenographer daemon owns: its launchd label, log subsystems, keychain services, localhost ports, and the directories and files it uses on disk. The daemon, the app and the `steno` tool read these values instead of spelling them again.

Stenographer 1.0.173 renamed the product's identifiers. The `legacy*` values are the pre-1.0.173 Stenographer names: they are read, matched and migrated, and never written. Because the daemon migrates the legacy support directory to the current one at its own pace, `StenographerPaths` resolves which directory holds the user's data at the moment it is asked, and offers `writeSupportFile` to follow the directory if it moves under a write.

`StenographerIdentifiers` is a caseless enum of static constants and one function. `StenographerPaths` is a `Sendable` struct that derives every path from one injectable home directory and one injectable existence check.

