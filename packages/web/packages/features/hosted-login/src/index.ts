// The hosted Hydra login page's body: a server component the hub's `/oidc/login` and the
// product site's `/login` both mount. No "use client": it renders native forms that post
// straight to the backend.
export { HostedLogin, MissingChallengeCard, type HostedLoginParams } from "./HostedLogin";
export { toHostedLoginParams, type NextSearchParams } from "./searchParams";
export {
  fetchHostedLoginContext,
  type HostedLoginContext,
  type HostedLoginProvider,
  type HostedLoginSignupMode,
} from "./loginContext";
