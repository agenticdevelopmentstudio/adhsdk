import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @adh-sdk/ui run test`
// (cwd = this package) discovers src/__tests__/*. Vitest walks up to the
// workspace-root config but keeps cwd as its root, so that config's
// `dir: './packages'` would resolve to `<this package>/packages` and match
// nothing — a green run of zero files. We reuse the root setup file for its
// deterministic jest-dom/localStorage/ResizeObserver/matchMedia shims (see
// packages/web/vitest.setup.ts), plus a package-local setup for the
// @base-ui/react Dialog getComputedStyle patch this package's dialog-based
// components (AlertModal, Combobox, DropdownMenu, ...) need.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts', './vitest.setup.ts'],
    dir: 'src',
  },
})
