// @vitest-environment node
// src/theme-data.ts is generated (gitignored, rebuilt by build:data, build, dev, lint and
// postinstall). Editing a stylesheet without regenerating leaves ThemeStyle injecting the
// old CSS with no error anywhere; this test fails instead.
import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
// @ts-expect-error -- plain .mjs build helper, no type declarations
import { renderThemeData } from '../../scripts/theme-data.mjs'

const stylesDir = fileURLToPath(new URL('../styles', import.meta.url))
const generated = fileURLToPath(new URL('../theme-data.ts', import.meta.url))

describe('theme-data.ts', () => {
  it('matches what the generator renders from the stylesheets now', async () => {
    const { text } = (await renderThemeData(stylesDir)) as { text: string }
    expect(await readFile(generated, 'utf8')).toBe(text)
  })
})
