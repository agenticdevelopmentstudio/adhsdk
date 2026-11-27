
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 3.0.1 | 2026-11-27 | Mike Fullerton | link-provider: the AS fallback never follows the configured API base; current login_methods path |
| 3.0.0 | 2026-11-26 | Mike Fullerton | Breaking: ProductAdminAuthProvider takes a required authBase prop that builds every auth URL (<authBase>/session, /signin, /signout), with trailing slashes dropped; stepUpSigninUrl(authBase, returnPath) gained a leading argument; the in-flight session request is keyed by its URL |
| 2.1.1 | 2026-11-23 | Mike Fullerton | The public reads use the shared token-free publicJson from the Auth v1 Wire Conventions; behaviour unchanged. |
| 2.1.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 2.0.0 | 2026-11-23 | Mike Fullerton | Phase 6: the access-token source seam and ProductAdminAuthProvider, the product admin site's in-memory session |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (conformance-vectors.test.ts, 119 of 120 vectors; auth-client-118 skipped as a static property); vector text corrected to the /v1 API; unit-test-coverage now passed. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Cite separation-of-concerns and unit-test-coverage in Compliance. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to data/services/auth/. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations; recipes cite files and symbols, not lines. |
