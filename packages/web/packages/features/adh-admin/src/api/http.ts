"use client";

// Auth HTTP logic now lives in @adh-sdk/auth. Re-exported here so the
// admin's api modules keep importing from "./http".
export {
  authedJson,
  authedRequest,
  exchangeSsoCode,
  extractErrorMessage,
  readErrorMessage,
  tokensFromResponse,
  readAccessToken,
  type BackendTokenFields,
} from "@adh-sdk/auth/client";
