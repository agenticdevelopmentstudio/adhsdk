// Runtime unit tests for the pure response→view mapper in ../applications-prototype. These
// verify the field renames, null-defaulting, and enum coercion that sit between the spec-typed
// backend rows and the UI view models — the logic the type system can't check (a wrong rename
// still type-checks).
//
// Moved here from the hub with its subject. The sibling mapper tests (toTeam / toEcosystem /
// monitored-sites) went to @adh-sdk/data earlier, each into its own domain's __tests__;
// toApp stayed behind only because applications-prototype was still hub glue, and it no longer is.
import { describe, expect, it } from "vitest";
import { toApp } from "../applications-prototype";

type Row<F extends (arg: never) => unknown> = Parameters<F>[0];
const as = <F extends (arg: never) => unknown>(o: Record<string, unknown>): Row<F> =>
  o as unknown as Row<F>;

describe("toApp", () => {
  it("maps id→id+identifier and display_name→name", () => {
    const a = toApp(
      as<typeof toApp>({
        id: "com.acme.app",
        display_name: "App",
        consumer_kind: "staff",
        ecosystem_id: "e",
        created: 1_700_000_000,
        updated: 1_700_000_060,
      }),
    );
    expect(a.identifier).toBe("com.acme.app");
    expect(a.name).toBe("App");
    expect(a.ecosystemId).toBe("e");
    expect(a.createdAt).toBe("2023-11-14T22:13:20.000Z");
    expect(a.updatedAt).toBe("2023-11-14T22:14:20.000Z");
  });
  it("maps the platform, defaulting a missing or unknown one to web", () => {
    const row = { id: "i", display_name: "n", consumer_kind: "staff", ecosystem_id: "e", created: 0, updated: 0 };
    expect(toApp(as<typeof toApp>({ ...row, platform: "native" })).platform).toBe("native");
    expect(toApp(as<typeof toApp>({ ...row, platform: "tv" })).platform).toBe("web");
  });
});
