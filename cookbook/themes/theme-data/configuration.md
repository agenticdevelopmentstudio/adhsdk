
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| styles directory | path | `src/styles` under the working directory | Where the script reads `.css` files; fixed in the script |
| output file | path | `src/theme-data.ts` under the working directory | Where the script writes; fixed in the script |
| `build:data` | npm script | `node scripts/build-theme-data.mjs` | Runs the generator by hand |
| `postinstall` | npm script | `node scripts/build-theme-data.mjs` | Runs the generator after install |
| `build` | npm script | `build:tokens`, `build:data`, then `tsup`, `build:types` and `build:css` | Runs the generator through `build:data` before bundling |
| `dev` | npm script | `build:tokens`, `build:data`, then `tsup --watch` | Runs the generator through `build:data` before watching |
| `lint` | npm script | `build:data`, then `tsc --noEmit` and the font-subset test | Runs the generator through `build:data` before type-checking |

The script takes no command-line argument and reads no environment variable.

