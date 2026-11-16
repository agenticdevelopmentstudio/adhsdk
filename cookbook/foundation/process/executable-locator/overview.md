
Finds a command-line tool by bare name the way a shell would, then in the install locations a GUI app's inherited `PATH` leaves out. An app started from the Dock or by launchd inherits only the system directories, so a tool installed by Homebrew or into `/usr/local/bin` is invisible to a plain `PATH` walk. `ExecutableLocator` is a `Sendable` value with no knowledge of any particular tool: `find(_:)` answers the first executable of that name, `searchDirectories` says where it looked.

