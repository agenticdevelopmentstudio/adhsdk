import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @adh-sdk/themes run test`
// (cwd = this package) discovers src/__tests__/* (the workspace-root config's
// `dir: '../packages'` resolves outside the web workspace, so it finds nothing —
// see the @adh-sdk/ui package for the same pattern). `passWithNoTests`
// stays on even though src/__tests__ is populated now, so a future PR that empties it
// (a rewrite in flight, a package split) keeps `test` green rather than failing on
// having nothing left to run.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
    passWithNoTests: true,
  },
})
