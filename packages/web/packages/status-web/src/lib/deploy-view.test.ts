import { describe, expect, it } from "vitest";
import { shownDeployStatus, shownPlatformSummary } from "./deploy-view";
import type { PlatformSummary } from "./live-types";

const AT = "2026-11-06T12:10:00.000Z";
const atMs = Date.parse(AT);

describe("shownDeployStatus", () => {
  it("shows the server's verdict until the server's deadline, then unknown", () => {
    const d = { effectiveStatus: "building" as const, unconfirmedAt: AT };
    expect(shownDeployStatus(d, atMs - 1)).toBe("building");
    expect(shownDeployStatus(d, atMs)).toBe("building");
    expect(shownDeployStatus(d, atMs + 1)).toBe("unknown");
  });

  it("never ages a deploy the server gave no deadline", () => {
    expect(shownDeployStatus({ effectiveStatus: "success", unconfirmedAt: null }, atMs + 86_400_000)).toBe("success");
    // An older backend sends no field at all: its verdict is shown as given.
    const old = { effectiveStatus: "building" } as { effectiveStatus: "building"; unconfirmedAt: string | null };
    expect(shownDeployStatus(old, atMs + 86_400_000)).toBe("building");
  });

  it("fails closed on a deadline it cannot read", () => {
    expect(shownDeployStatus({ effectiveStatus: "queued", unconfirmedAt: "nope" }, atMs)).toBe("unknown");
  });
});

describe("shownPlatformSummary", () => {
  const pill: PlatformSummary = {
    platform: "vercel",
    ready: 3,
    building: 2,
    buildingUnconfirmedAt: [AT, "2026-11-06T12:20:00.000Z"],
    failed: 0,
    total: 5,
  };

  it("drops each building deploy from the count once its deadline passes, keeping the total", () => {
    expect(shownPlatformSummary(pill, atMs)).toBe(pill);
    expect(shownPlatformSummary(pill, atMs + 1)).toMatchObject({ building: 1, total: 5, ready: 3 });
    expect(shownPlatformSummary(pill, Date.parse("2026-11-06T12:30:00.000Z"))).toMatchObject({ building: 0 });
  });

  it("leaves a pill from an older backend, with no deadlines, as given", () => {
    const old = { platform: "vercel", ready: 0, building: 1, failed: 0, total: 1 } as PlatformSummary;
    expect(shownPlatformSummary(old, atMs + 86_400_000).building).toBe(1);
  });
});
