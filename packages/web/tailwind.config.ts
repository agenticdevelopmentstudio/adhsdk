import type { Config } from 'tailwindcss'

// Tailwind arrived with @adh-sdk/ui in 2026-08. The nine packages
// that predate it author plain CSS and must keep working untouched — nothing here
// scans them, and no package is required to adopt Tailwind to build.
export default {
  content: ['./packages/ui/src/**/*.{ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
} satisfies Config
