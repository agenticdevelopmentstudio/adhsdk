
- **SwiftUI**: Not used; the type has no view layer, though a settings screen can show `lastError(of:)` beside the display toggle.
- **Compose**: Port with `java.nio.file` (`Files.createDirectories` with `PosixFilePermissions`, temp file then `Files.move` with `ATOMIC_MOVE`) and a plain data class for `Entry`.
- **React/Web**: Node `fs` with `mode` options and write-file-atomic; browsers cannot reach this directory.
- **AppKit / UIKit**: `Core/ClaudeHooks/ClaudeStatusLine.swift`, an internal (not `public`) struct that `ClaudeHookInstaller` holds, using `FileManager`, `CharacterSet` for name validation and `AtomicFile.write` for mode-at-creation writes; the command is quoted by `Core/Process/ShellQuoting.swift`. No UI framework is involved, so the same code serves both.
- **WinUI 3**: Use `System.IO` (`Directory.CreateDirectory`, `File.ReadAllTextAsync`, `File.Replace` over a temp file) and `Windows.Storage` for the Claude directory. POSIX modes do not exist, so `0700` and `0600` map to owner-only ACLs through `FileSecurity`; the `0755` dispatcher becomes an ordinary file. Quote commands with Windows argument rules, not POSIX single quotes, and note the dispatcher is a `sh` script, so the Windows Claude Code location may need a `.cmd` or PowerShell dispatcher instead. Methods return `Task` when called from a service and use `Task.Run` off the UI thread; `Entry` is a `record`.

