import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @agenticdevelopertoolkit/analytics run test`
// (cwd = this package) discovers src/__tests__/*, the same pattern as themes and ui.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
  },
})
