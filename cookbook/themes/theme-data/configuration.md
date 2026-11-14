
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| styles directory | path | `src/styles` under the working directory | Where the script reads `.css` files; fixed in the script |
| output file | path | `src/theme-data.ts` under the working directory | Where the script writes; fixed in the script |
| `build:data` | npm script | `node scripts/build-theme-data.mjs` | Runs the generator by hand |
| `postinstall` | npm script | `node scripts/build-theme-data.mjs` | Runs the generator after install |

The script takes no command-line argument and reads no environment variable.

