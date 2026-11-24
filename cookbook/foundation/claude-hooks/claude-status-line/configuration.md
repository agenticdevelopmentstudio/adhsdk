| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `claudeDirectory` | `URL` | required | The directory holding `settings.json` (`~/.claude`) |
| `bundledDispatcher` | `URL` | required | The dispatcher this build carries (`Contents/Resources/dispatch.sh`) |

Contract constants, fixed byte for byte by **dispatcher-command**, **settings-lock-name** and **owner-only-tree** and not configurable:

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `marker` | `String` | `# claudehelpers-statusline` | Ends the dispatcher's `statusLine.command` |
| `settingsLockName` | `String` | `.settings.lock` | Shared lock file name beside `settings.json` |
| `adoptedName` | `String` | `adopted` | Base name for an adopted foreign command |
| directory modes | `mode_t` | `0700` | Every directory in the tree |
| entry modes | `mode_t` | `0600` | Every entry; the dispatcher is written `0755` |
