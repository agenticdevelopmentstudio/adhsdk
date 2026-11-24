import { defineConfig } from 'vitest/config'

// `dir: 'src'` keeps the run to src/__tests__ — the two spec-drift gates. They read
// adh's /v1 spec (openapi.v1.json), which is NOT in this repo: it arrives via
// ADH_OPENAPI_SPEC and the gates skip (loudly) when it is unset. The exposure check
// also reads the legacy openapi.json beside it (or ADH_OPENAPI_LEGACY_SPEC). See
// src/__tests__/adh-spec.ts.
export default defineConfig({
  test: {
    environment: 'node',
    dir: 'src',
  },
})
