
`ADKDIdentifiers` and `ADKDPaths` are the single spelling of every name the Kitchen daemon (`adkd`) owns: its launchd label, log subsystems, keychain service, localhost HTTP port, hook and lock names, executable names, and every file and directory it uses on disk. The daemon, its command-line tool and the app that hosts it all read these values instead of spelling them again. The daemon has no history, so there are no legacy names to read or migrate.

The values that could collide differ from the Stenographer daemon's (`StenographerIdentifiers`, `StenographerPaths`); only the launchd output file names `stdout.log` and `stderr.log` are the same, and they sit in separate logs directories. Both daemons run on one machine without sharing a label, a port, a hook marker or a directory. `ADKDIdentifiers` is a caseless enum of static constants. `ADKDPaths` is a `Sendable` struct that derives every path from one injectable home directory.

