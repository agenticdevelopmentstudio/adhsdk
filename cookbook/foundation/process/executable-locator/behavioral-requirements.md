
- **path-first**: `find(name)` MUST try each `PATH` entry of `environment`, in order, before any extra directory.
- **extra-directories-after**: `find(name)` MUST try `extraDirectories`, in order, after every `PATH` entry.
- **default-extras**: The default `extraDirectories` MUST be `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`, in that order.
- **de-duplicated**: A directory that appears more than once across `PATH` and `extraDirectories` MUST be tried only at its first place. A trailing `/` MUST NOT make a directory distinct, and an empty or relative (not `/`-led) entry MUST be dropped.
- **first-executable-wins**: `find(name)` MUST return the first `<directory>/<name>` for which `isExecutable` answers true, and MUST NOT test any later candidate.
- **nil-when-absent**: `find(name)` MUST return nil when no candidate is executable.
- **bare-name-only**: `find(name)` MUST return nil without testing any path when `name` is empty or contains `/`.
- **injected-check**: Whether a path is executable MUST be answered only by the injected `isExecutable`, which defaults to `FileManager.isExecutableFile(atPath:)` for a path that is not a directory. The locator MUST NOT run a process.
- **tool-agnostic**: The locator MUST NOT hold any tool-specific location; a tool with locations of its own passes them as `extraDirectories`.

