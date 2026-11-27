// Unit tests for toHostedLoginParams: the hosted login page's mounts pass Next's
// searchParams through it, so a repeated query key (an array) never reaches HostedLogin,
// whose string methods would throw on it (review 2026-11-27, f6).
import { describe, expect, it } from "vitest";
import { toHostedLoginParams } from "../searchParams";

describe("toHostedLoginParams", () => {
  it("keeps plain string values", () => {
    expect(toHostedLoginParams({ login_challenge: "c1", mfa_token: "t" })).toEqual({
      login_challenge: "c1",
      mfa_token: "t",
    });
  });

  it("keeps the first value of a repeated key", () => {
    expect(toHostedLoginParams({ mfa: ["a", "b"], login_challenge: ["c1", "c2"] })).toEqual({
      mfa: "a",
      login_challenge: "c1",
    });
  });

  it("drops an empty array, an undefined value and an unknown key", () => {
    expect(toHostedLoginParams({ mfa: [], error: undefined, other: "x" })).toEqual({});
  });
});
