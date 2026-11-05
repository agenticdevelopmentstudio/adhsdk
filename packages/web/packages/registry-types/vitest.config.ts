import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @adh-sdk/registry-types
// run test` (cwd = this package) discovers src/__tests__/*. Vitest walks up to
// the workspace-root config but keeps cwd as its root, so the root's
// `dir: './packages'` resolves to <this package>/packages — which does not
// exist, and the run finds nothing. That silence used to be masked by
// `--passWithNoTests` on the test script: three real test files, a green exit,
// zero of them run. We reuse the root setup file for its deterministic
// jest-dom/localStorage/ResizeObserver/matchMedia shims.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
  },
})
