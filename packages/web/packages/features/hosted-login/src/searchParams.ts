import type { HostedLoginParams } from "./HostedLogin";

/** What Next hands a page as its `searchParams`: a repeated key arrives as an array. */
export type NextSearchParams = Record<string, string | string[] | undefined>;

/** Every key HostedLoginParams names, so the copy below can never miss one. */
const PARAM_KEYS = [
  "login_challenge",
  "error",
  "mfa",
  "mfa_token",
  "mode",
  "verify",
  "verify_token",
  "code_sent",
] as const satisfies readonly (keyof HostedLoginParams)[];

/**
 * Next's `searchParams` as HostedLoginParams, keeping the first value of a repeated key
 * (`?mfa=a&mfa=b` → `"a"`), as `URLSearchParams.get` does. HostedLogin calls string methods
 * on these values, so before this a repeated key handed it an array and the login page
 * answered 500 (review 2026-11-27, f6). Keys it does not name are dropped. Pure; never throws.
 */
export function toHostedLoginParams(searchParams: NextSearchParams): HostedLoginParams {
  const params: HostedLoginParams = {};
  for (const key of PARAM_KEYS) {
    const raw = searchParams[key];
    const value = Array.isArray(raw) ? raw[0] : raw;
    if (typeof value === "string") params[key] = value;
  }
  return params;
}
