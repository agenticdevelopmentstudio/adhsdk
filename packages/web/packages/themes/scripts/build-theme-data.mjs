#!/usr/bin/env node
// Reads packages/themes/src/styles/*.css and emits src/theme-data.ts
// with string-literal exports keyed by file basename. Runs as prebuild. A relative @import is
// inlined (inline-imports.mjs), so each string is the whole theme ThemeStyle injects.
// The text itself comes from theme-data.mjs, which the theme-data sync test also reads.
import { writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { renderThemeData } from './theme-data.mjs'

const STYLES_DIR = resolve('src/styles')
const OUT = resolve('src/theme-data.ts')

const { text, count } = await renderThemeData(STYLES_DIR)
await writeFile(OUT, text, 'utf8')
console.log(`build-theme-data: ${count} theme${count === 1 ? '' : 's'} → src/theme-data.ts`)
